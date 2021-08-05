//This file contains the vertex and fragment functions for both the ForwardBase and Forward Add pass.

v2f vert (appdata v)
{
    v2f o = (v2f)0;
    float3 worldNormal = UnityObjectToWorldNormal(v.normal);
    float3 tangent = UnityObjectToWorldDir(v.tangent);
    float3 bitangent = cross(tangent, worldNormal) * v.tangent.w;

    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.uv, _MainTex;
    #if defined(UNITY_PASS_FORWARDBASE)
    o.uv1 = v.uv1;
    o.uv2 = v.uv2;
    #endif

    o.btn[0] = bitangent;
    o.btn[1] = tangent;
    o.btn[2] = worldNormal;
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    o.objPos = v.vertex;
    o.objNormal = v.normal;
    o.screenPos = ComputeScreenPos(o.pos);

    #if !defined(UNITY_PASS_SHADOWCASTER)
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
        float4 albedo = TextureSampleAdv(i, _MainTex, _MainTex_ST) * _Color;
        float alpha;
        doAlpha(alpha, albedo.a, i.screenPos);
        SHADOW_CASTER_FRAGMENT(i);
    #else
        FragmentData o = (FragmentData)0;

        float4 color = TextureSampleAdv(i, _MainTex, _MainTex_ST) * _Color;
        float4 emissionColor = TextureSampleAdv(i, _EmissionMap, _EmissionMap_ST) * _EmissionColor;
        float4 metallicGlossMap = TextureSampleAdv(i, _MetallicGlossMap, _MetallicGlossMap_ST);
        float4 clearcoatMap = TextureSampleAdv(i, _ClearcoatMap, _ClearcoatMap_ST);
        float4 normalMap = TextureSampleAdv(i, _BumpMap, _BumpMap_ST);
        float4 occlusionMap = TextureSampleAdv(i, _OcclusionMap, _OcclusionMap_ST);
        float4 curvatureThicknessMap = TextureSampleAdv(i, _CurvatureThicknessMap, _CurvatureThicknessMap_ST);
        float4 subsurfaceColorMap = TextureSampleAdv(i, _CurvatureThicknessMap, _CurvatureThicknessMap_ST);

        o.Albedo = color;
        o.Normal = normalMap;
        o.Emission = emissionColor;
        o.Metallic = metallicGlossMap.r * _Metallic;
        o.Reflectance = metallicGlossMap.g * _Reflectance;
        o.Smoothness = metallicGlossMap.a * _Glossiness;
        o.ClearcoatSmoothness = clearcoatMap.a * _ClearcoatGlossiness;
        o.ClearcoatReflectance = clearcoatMap.r * _Clearcoat;
        o.Occlusion = occlusionMap;
        o.Curvature = curvatureThicknessMap.r;
        o.Thickness = curvatureThicknessMap.g;
        o.SubsurfaceTransmissionMask = curvatureThicknessMap.b;
        o.SubsurfaceColor = subsurfaceColorMap * _SubsurfaceScatteringColor * lerp(1, o.Albedo, _SubsurfaceInheritDiffuse);
        o.Alpha = color.a;
        return CustomStandardLightingBRDF(i, o);
    #endif
}