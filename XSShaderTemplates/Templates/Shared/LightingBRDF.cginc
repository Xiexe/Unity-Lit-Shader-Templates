//Since this is shared, and the output structs/input structs are all slightly differently named in each shader template, just handle them all here.
float4 CustomStandardLightingBRDF(
    #if defined(GEOMETRY)
        g2f i
    #elif defined(TESSELLATION)
        vertexOutput i
    #else
        v2f i
    #endif
    )
{
    //LIGHTING PARAMS
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
    float3 worldPos = i.worldPos;

    //NORMAL
    float3 unmodifiedWorldNormal = normalize(i.btn[2]);
    float4 normalMap = texTP(_BumpMap, _MainTex_ST, i.worldPos, i.objPos, i.btn[2], i.objNormal, _TriplanarFalloff, i.uv);
    float3 worldNormal = getNormal(normalMap, i.btn[0], i.btn[1], i.btn[2]);

    //METALLIC SMOOTHNESS
    float4 metallicGlossMap = texTP(_MetallicGlossMap, _MainTex_ST, i.worldPos, i.objPos, i.btn[2], i.objNormal, _TriplanarFalloff, i.uv);
    float4 metallicSmoothness = getMetallicSmoothness(metallicGlossMap);
    float metallic = metallicSmoothness.r;
    float reflectance = _Reflectance;
    float roughness = metallicSmoothness.a;

    //CLEARCOAT MAP
    float4 clearcoatMap = texTP(_ClearcoatMap, _MainTex_ST, i.worldPos, i.objPos, i.btn[2], i.objNormal, _TriplanarFalloff, i.uv);
    float4 clearcoatReflectivitySmoothness = getClearcoatSmoothness(clearcoatMap);
    float clearcoatReflectivity = clearcoatReflectivitySmoothness.r;
    float clearcoatRoughness = clearcoatReflectivitySmoothness.a;

    //DIFFUSE
    float4 albedo = texTP(_MainTex, _MainTex_ST, i.worldPos, i.objPos, i.btn[2], i.objNormal, _TriplanarFalloff, i.uv) * _Color;
    float3 diffuse = albedo;
    albedo.rgb *= (1-metallic);

    float3 lightDir = getLightDir(i.worldPos);
    float4 lightCol = _LightColor0;

    //LIGHTING VECTORS
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
    float3 halfVector = normalize(lightDir + viewDir);
    float3 reflViewDir = reflect(-viewDir, worldNormal);
    float3 reflLightDir = reflect(lightDir, worldNormal);

    //DOT PRODUCTS FOR LIGHTING
    float ndl = saturate(dot(lightDir, worldNormal));
    float vdn = abs(dot(viewDir, worldNormal));
    float vdh = saturate(dot(viewDir, halfVector));
    float rdv = saturate(dot(reflLightDir, float4(-viewDir, 0)));
    float ldh = saturate(dot(lightDir, halfVector));
    float ndh = saturate(dot(worldNormal, halfVector));

    //LIGHTING
    //Diffuse BRDF
    #if defined(LIGHTMAP_ON)
        float3 indirectDiffuse = 0;
        float3 directDiffuse = albedo * getLightmap(i.uv1, worldNormal, i.worldPos);
        #if defined(DYNAMICLIGHTMAP_ON)
            float3 realtimeLM = getRealtimeLightmap(i.uv2, worldNormal);
            directDiffuse += realtimeLM;
        #endif
    #else
        //Gather up non-important lights
        float3 vertexLightData = 0;
        #if defined(VERTEXLIGHT_ON)
            VertexLightInformation vLight = (VertexLightInformation)0;
            float4 vertexLightAtten = float4(0,0,0,0);
            float3 vertexLightColor = get4VertexLightsColFalloff(vLight, worldPos, worldNormal, vertexLightAtten);
            float3 vertexLightDir = getVertexLightsDir(vLight, worldPos, vertexLightAtten);
            for(int i = 0; i < 4; i++)
            {
                vertexLightData += saturate(dot(vLight.Direction[i], worldNormal)) * vLight.ColorFalloff[i];
            }
        #endif

        float3 indirectDiffuse = getIndirectDiffuse(worldNormal) + vertexLightData;
        float3 atten = (attenuation * ndl * lightCol) + indirectDiffuse;
        float3 directDiffuse = (albedo * atten);
    #endif

    //Specular BRDF
    // This is a pretty big hack of a specular brdf but I didn't like other implementations entirely. This is my own, mixed with some other stuff from other places.
    // This probably means it breaks energy conservation, fails the furnace test, etc, but, in my opinion, it looks better.
    float3 f0 = 0.16 * reflectance * reflectance * (1.0 - metallic) + diffuse * metallic;
    float3 schlickFresnel = F_Schlick(vdn, f0);
    float3 fresnel = lerp(schlickFresnel, f0, metallic);
    float3 directSpecular = getDirectSpecular(diffuse, metallic, roughness, ndh, vdn, ndl, ldh, f0) * attenuation * ndl * lightCol;
    float3 indirectSpecular = getIndirectSpecular(metallic, roughness, reflViewDir, worldPos, directDiffuse); //Lightmap is stored in directDiffuse and used for specular lightmap occlusion

    float3 vertexLightSpec = 0;
    #if defined(VERTEXLIGHT_ON)
        for(int i = 0; i < 4; i++)
        {
            float3 vHalfVector = normalize(vLight.Direction[i] + viewDir);
            float vNDL = saturate(dot(vLight.Direction[i], worldNormal));
            float vLDH = saturate(dot(vLight.Direction[i], halfVector));
            float vNDH = saturate(dot(worldNormal, vHalfVector));
            float vLspec = getDirectSpecular(diffuse, metallic, roughness, vNDH, vdn, vNDL, vLDH, f0) * vNDL;
            vertexLightSpec += vLspec * vLight.ColorFalloff[i];
        }
    #endif
    
    float3 specular = ((indirectSpecular + directSpecular + vertexLightSpec) * lerp(fresnel, f0, roughness)); //Personally i think the fresnel effect on dialectric materials looks bad, so lets kill it.

    //Clearcoat BRDF
    //LIGHTING VECTORS
    float3 creflViewDir = reflect(-viewDir, unmodifiedWorldNormal);

    //DOT PRODUCTS FOR LIGHTING
    float cndl = saturate(dot(lightDir, unmodifiedWorldNormal));
    float cvdn = abs(dot(viewDir, unmodifiedWorldNormal));;
    float cndh = saturate(dot(unmodifiedWorldNormal, halfVector));

    float3 clearcoatf0 = 0.16 * clearcoatReflectivity * clearcoatReflectivity;
    float3 clearcoatFresnel = F_Schlick(cvdn, clearcoatf0);
    float3 clearcoatDirectSpecular = getDirectSpecular(diffuse, 0, clearcoatRoughness, cndh, cvdn, cndl, ldh, clearcoatf0) * attenuation * cndl * lightCol;
    float3 clearcoatIndirectSpecular = getIndirectSpecular(0, clearcoatRoughness, creflViewDir, worldPos, directDiffuse);
    float3 clearcoat = (clearcoatDirectSpecular + clearcoatIndirectSpecular) * clearcoatReflectivity * clearcoatFresnel;
    // return clearcoat.xyzz;

    //TODO: Implement subsurface scattering

    float3 lighting = (directDiffuse ) + specular + clearcoat;
    float al = 1;
    #if defined(alphablend)
        al = albedo.a;
    #endif

    return float4(lighting, al);
}