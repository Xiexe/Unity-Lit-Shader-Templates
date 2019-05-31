//This file contains the vertex and fragment functions for both the ForwardBase and Forward Add pass.

v2f vert (appdata v)
{
    v2f o;
    float3 worldNormal = UnityObjectToWorldNormal(v.normal);
    float3 tangent = UnityObjectToWorldDir(v.tangent);
    float3 bitangent = cross(tangent, worldNormal);

    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    #if defined(UNITY_PASS_FORWARDBASE)
    o.uv1 = v.uv1;
    o.uv2 = v.uv2;
    #endif
    
    #if !defined(UNITY_PASS_SHADOWCASTER)
    o.btn[0] = bitangent;
    o.btn[1] = tangent;
    o.btn[2] = worldNormal;
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    o.objPos = v.vertex;
    o.objNormal = v.normal;
    UNITY_TRANSFER_SHADOW(o, o.uv);
    #else
    TRANSFER_SHADOW_CASTER_NOPOS(o, o.pos);
    #endif

    return o;
}
			
fixed4 frag (v2f i) : SV_Target
{
    //Return only this if in the shadowcaster
    #if defined(UNITY_PASS_SHADOWCASTER)
        SHADOW_CASTER_FRAGMENT(i);
    #else
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
            float3 indirectDiffuse = ShadeSH9(float4(worldNormal, 1));
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
    #endif
}