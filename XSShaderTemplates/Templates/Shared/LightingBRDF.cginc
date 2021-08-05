//Since this is shared, and the output structs/input structs are all slightly differently named in each shader template, just handle them all here.
float4 CustomStandardLightingBRDF(
    #if defined(GEOMETRY)
        g2f i,
    #elif defined(TESSELLATION)
        vertexOutput i,
    #else
        v2f i,
    #endif

        FragmentData fragIN
    )
{
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
	#ifdef UNITY_PASS_FORWARDBASE
        // fix for rare bug where light atten is 0 when there is no directional light in the scene
		if(all(_LightColor0.rgb == 0.0)){ attenuation = 1.0; }
	#endif

    FragmentData surface = fragIN; //Make a copy so we can modify it a bit.
    NormalData normal_data = (NormalData)0;
    DotProducts dot_products = (DotProducts)0;
    LightingVectors lighting_vectors = (LightingVectors)0;
    float3 worldPos = i.worldPos;
    surface.Albedo = fragIN.Albedo * (1-fragIN.Metallic);
    surface.Smoothness = 1-fragIN.Smoothness; // Convert Smoothness to Roughness.
    surface.ClearcoatSmoothness = getSquaredRoughness(1-fragIN.ClearcoatSmoothness);
    surface.Occlusion = lerp(_OcclusionColor, 1, fragIN.Occlusion);
    #if defined(UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_META) // Emissions should only happen in the forward base pass (and meta pass)
        surface.Emission = fragIN.Emission.rgb;
    #else
        surface.Emission = 0;
    #endif
    PopulateLightingStructs(i, surface, normal_data, dot_products, lighting_vectors);

    float3 diffuseNDL = dot_products.ndl; //Modified for diffuse if using Subsurface Preintegrated mode, otherwise use normal Lambertian NDL.

    float3 directDiffuse = 0;
    float3 indirectDiffuse = 0;
    //Diffuse BRDF
    #if defined(LIGHTMAP_ON)
        directDiffuse = surface.Albedo * getLightmap(i.uv1, normal_data.BumpedWorldNormal, worldPos);
        #if defined(DYNAMICLIGHTMAP_ON)
            float3 realtimeLM = getRealtimeLightmap(i.uv2, worldNormal);
            directDiffuse += realtimeLM;
        #endif

        float3 atten = (attenuation * diffuseNDL * lighting_vectors.lightCol) + indirectDiffuse;
        directDiffuse += surface.Albedo * atten;
    #else
        //Gather up non-important lights
        float3 vertexLightData = 0;
        #if defined(VERTEXLIGHT_ON) && !defined(LIGHTMAP_ON)
            VertexLightInformation vLight = (VertexLightInformation)0;
            float4 vertexLightAtten = float4(0,0,0,0);
            float3 vertexLightColor = get4VertexLightsColFalloff(vLight, worldPos, normal_data.BumpedWorldNormal, vertexLightAtten);
            float3 vertexLightDir = getVertexLightsDir(vLight, worldPos, vertexLightAtten);
            for(int l = 0; l < 4; l++)
            {
                vertexLightData += saturate(dot(vLight.Direction[l], normal_data.BumpedWorldNormal)) * vLight.ColorFalloff[l];
            }
        #endif
        indirectDiffuse = (getIndirectDiffuse(normal_data.BumpedWorldNormal) * surface.Occlusion) + vertexLightData;
        float3 atten = (attenuation * diffuseNDL * lighting_vectors.lightCol) + indirectDiffuse;
        directDiffuse = surface.Albedo * atten;
    #endif

    if(_SubsurfaceMethod == 1)
    {
        //Calculates a Subsurface Scattering LUT with some cursed ass shit.
        float3 transmission = getTransmission(surface.SubsurfaceColor, attenuation, fragIN.Albedo, 1-surface.Thickness, lighting_vectors.lightDir, lighting_vectors.viewDir, normal_data.BumpedWorldNormal, lighting_vectors.lightCol, indirectDiffuse);
        float3 subsurface = getSubsurfaceFalloff(dot_products.ndl01, dot_products.rawNdl, surface.Curvature, surface.SubsurfaceColor);
        diffuseNDL = lerp(subsurface + transmission, dot_products.ndl, surface.SubsurfaceTransmissionMask);
    }
    //----

    //Specular BRDF
    // This is a pretty big hack of a specular brdf but I didn't like other implementations entirely. This is my own, mixed with some other stuff from other places.
    // This probably means it breaks energy conservation, fails the furnace test, etc, but, in my opinion, it looks better.
    // This makes things look a little bit better in baked lighting by forcing a "direct" specular highlight to always be visible by getting the dominant light probe direction and color.
        float3 f0 = 0.16 * surface.Reflectance * surface.Reflectance * (1.0 - surface.Metallic) + fragIN.Albedo * surface.Metallic;
        float3 fresnel = lerp(F_Schlick(dot_products.vdn, f0), f0, surface.Metallic); //Kill fresnel on metallics, it looks bad.
        float3 directSpecular = getDirectSpecular(surface.Smoothness, dot_products.ndh, dot_products.vdn, dot_products.ndl, dot_products.ldh, f0, lighting_vectors.lvHalfVector, normal_data.BumpedTangent, normal_data.BumpedBitangent, _Anisotropy) * attenuation * dot_products.ndl * lighting_vectors.lightCol;
        float3 indirectSpecular = getIndirectSpecular(surface.Metallic, surface.Smoothness, lighting_vectors.reflViewDir, worldPos, directDiffuse, normal_data.BumpedWorldNormal) * lerp(fresnel, f0, surface.Smoothness);

    //TODO: Move this into its own function...
        float3 vertexLightSpec = 0;
        float3 vertexLightClearcoatSpec = 0;
        #if defined(VERTEXLIGHT_ON) && !defined(LIGHTMAP_ON)
            [unroll(4)]
            for(int l = 0; l < 4; l++)
            {
                // All of these need to be recalculated for each individual light to treat them how we want to treat them.
                float3 vHalfVector = normalize(vLight.Direction[l] + lighting_vectors.viewDir);
                float vNDL = saturate(dot(vLight.Direction[l], normal_data.BumpedWorldNormal));
                float vLDH = saturate(dot(vLight.Direction[l], vHalfVector));
                float vNDH = saturate(dot(normal_data.BumpedWorldNormal, vHalfVector));
                float vCndl = saturate(dot(vLight.Direction[l], normal_data.WorldNormal));
                float vCvdn = abs(dot(lighting_vectors.viewDir, normal_data.WorldNormal));
                float vCndh = saturate(dot(normal_data.WorldNormal, vHalfVector));

                float3 vLspec = getDirectSpecular(surface.Smoothness, vNDH, dot_products.vdn, vNDL, vLDH, f0, vHalfVector, normal_data.BumpedTangent, normal_data.BumpedBitangent, _Anisotropy) * vNDL;
                float3 vLspecCC = getDirectSpecular(surface.ClearcoatSmoothness, vCndh, vCvdn, vCndl, vLDH, f0, vHalfVector, normal_data.Tangent, normal_data.Bitangent, _ClearcoatAnisotropy) * vNDL;
                vertexLightSpec += vLspec * vLight.ColorFalloff[l];
                vertexLightClearcoatSpec += vLspecCC * vLight.ColorFalloff[l];
            }
        #endif
        float3 specular = (indirectSpecular + directSpecular + vertexLightSpec);
    //----

    //Clearcoat BRDF
        float3 creflViewDir = getAnisotropicReflectionVector(lighting_vectors.viewDir, normal_data.Bitangent, normal_data.Tangent, normal_data.WorldNormal, surface.ClearcoatSmoothness, _ClearcoatAnisotropy);
        float cndl = saturate(dot(lighting_vectors.lightDir, normal_data.WorldNormal));
        float cvdn = abs(dot(lighting_vectors.viewDir, normal_data.WorldNormal));
        float cndh = saturate(dot(normal_data.WorldNormal, lighting_vectors.lvHalfVector));

        float3 clearcoatf0 = 0.16 * surface.ClearcoatReflectance * surface.ClearcoatReflectance;
        float3 clearcoatFresnel = F_Schlick(cvdn, clearcoatf0);
        float3 clearcoatDirectSpecular = getDirectSpecular(surface.ClearcoatSmoothness, cndh, cvdn, cndl, dot_products.ldh, clearcoatf0, lighting_vectors.lvHalfVector, normal_data.Tangent, normal_data.Bitangent, _ClearcoatAnisotropy) * attenuation * cndl * lighting_vectors.lightCol;
        float3 clearcoatIndirectSpecular = getIndirectSpecular(0, surface.ClearcoatSmoothness, creflViewDir, worldPos, directDiffuse, normal_data.WorldNormal);
        float3 clearcoat = (clearcoatDirectSpecular + clearcoatIndirectSpecular + vertexLightClearcoatSpec) * surface.ClearcoatReflectance * clearcoatFresnel;
    //----

    //TODO: Implement subsurface scattering
    float3 litPixel = directDiffuse + ((specular + clearcoat) * surface.Occlusion) + surface.Emission;
    return float4(max(0, litPixel), surface.Alpha);
}