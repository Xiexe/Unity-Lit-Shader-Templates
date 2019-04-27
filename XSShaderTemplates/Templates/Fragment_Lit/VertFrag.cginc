//This file contains the vertex and fragment functions for both the ForwardBase and Forward Add pass.

v2f vert (appdata v)
{
    v2f o;
    float3 worldNormal = UnityObjectToWorldNormal(v.normal);
    float3 tangent = UnityObjectToWorldDir(v.tangent);
    float3 bitangent = cross(tangent, worldNormal);

    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    o.btn[0] = bitangent;
    o.btn[1] = tangent;
    o.btn[2] = worldNormal;
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);

    UNITY_TRANSFER_SHADOW(o, o.uv);
    return o;
}
			
fixed4 frag (v2f i) : SV_Target
{
    //LIGHTING PARAMS
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
    float3 lightDir = getLightDir(i.worldPos);
    float4 lightCol = _LightColor0;

    //METALLIC SMOOTHNESS
    float4 metallicGlossMap = tex2D(_MetallicGlossMap, i.uv);
    float4 metallicSmoothness = getMetallicSmoothness(metallicGlossMap);

    //DIFFUSE
    fixed4 diffuse = tex2D(_MainTex, i.uv) * _Color;
    fixed4 diffuseColor = diffuse; //Store for later use, we alter it after.
    diffuse *= (1-metallicSmoothness.x);
    
    //NORMAL
    float4 normalMap = tex2D(_BumpMap, i.uv);
    float3 worldNormal = getNormal(normalMap, i.btn[0], i.btn[1], i.btn[2]);

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
    
    float3 indirectDiffuse = ShadeSH9(float4(worldNormal, 1));
    float3 directDiffuse = ndl * attenuation * _LightColor0;
    
    float3 indirectSpecular = getIndirectSpecular(i.worldPos, diffuseColor, vdn, metallicSmoothness, reflViewDir, indirectDiffuse, viewDir, directDiffuse);
    float3 directSpecular = getDirectSpecular(lightCol, diffuseColor, metallicSmoothness, rdv, attenuation);

    lighting = diffuse * (directDiffuse + indirectDiffuse); 
    lighting += directSpecular; 
    lighting += indirectSpecular;

    float4 col = lighting.xyzz;
    return col;
}