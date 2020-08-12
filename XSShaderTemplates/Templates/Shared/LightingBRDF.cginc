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
    float3 lightDir = getLightDir(i.worldPos);
    float4 lightCol = _LightColor0;

    //NORMAL
    float3 normalMap = texTPNorm(_BumpMap, _MainTex_ST, i.worldPos, i.objPos, i.btn[2], i.objNormal, _TriplanarFalloff, i.uv);
    float3 worldNormal = getNormal(normalMap, i.btn[0], i.btn[1], i.btn[2]);

    //METALLIC SMOOTHNESS
    float4 metallicGlossMap = texTP(_MetallicGlossMap, _MainTex_ST, i.worldPos, i.objPos, i.btn[2], i.objNormal, _TriplanarFalloff, i.uv);
    float4 metallicSmoothness = getMetallicSmoothness(metallicGlossMap);

    //DIFFUSE
    fixed4 diffuse = texTP(_MainTex, _MainTex_ST, i.worldPos, i.objPos, i.btn[2], i.objNormal, _TriplanarFalloff, i.uv) * _Color;
    fixed4 diffuseColor = diffuse; //Store for later use, we alter it after.
    diffuse.rgb *= (1-metallicSmoothness.x);

    //LIGHTING VECTORS
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
    float3 halfVector = normalize(lightDir + viewDir);
    float3 reflViewDir = reflect(-viewDir, worldNormal);
    float3 reflLightDir = reflect(lightDir, worldNormal);

    //DOT PRODUCTS FOR LIGHTING
    float ndl = saturate(dot(lightDir, worldNormal));
    float vdn = abs(dot(viewDir, worldNormal));
    float rdv = saturate(dot(reflLightDir, float4(-viewDir, 0)));

    //LIGHTING
    float3 lighting = float3(0,0,0);

    #if defined(LIGHTMAP_ON)
        float3 indirectDiffuse = 0;
        float3 directDiffuse = getLightmap(i.uv1, worldNormal, i.worldPos);
        #if defined(DYNAMICLIGHTMAP_ON)
            float3 realtimeLM = getRealtimeLightmap(i.uv2, worldNormal);
            directDiffuse += realtimeLM;
        #endif
    #else
        float3 indirectDiffuse;
        if(_LightProbeMethod == 0)
        {
            indirectDiffuse = ShadeSH9(float4(worldNormal, 1));
        }
        else
        {
            float3 L0 = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
            indirectDiffuse.r = shEvaluateDiffuseL1Geomerics(L0.r, unity_SHAr.xyz, worldNormal);
            indirectDiffuse.g = shEvaluateDiffuseL1Geomerics(L0.g, unity_SHAg.xyz, worldNormal);
            indirectDiffuse.b = shEvaluateDiffuseL1Geomerics(L0.b, unity_SHAb.xyz, worldNormal);
        }

        float3 directDiffuse = ndl * attenuation * _LightColor0;
    #endif

    float3 indirectSpecular = getIndirectSpecular(i.worldPos, diffuseColor, vdn, metallicSmoothness, reflViewDir, indirectDiffuse, viewDir, directDiffuse);
    float3 directSpecular = getDirectSpecular(lightCol, diffuseColor, metallicSmoothness, rdv, attenuation);

    lighting = diffuse * (directDiffuse + indirectDiffuse); 
    lighting += directSpecular; 
    lighting += indirectSpecular;

    float al = 1;
    #if defined(alphablend)
        al = diffuseColor.a;
    #endif

    return float4(lighting, al);
}
