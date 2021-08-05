#include "Tessellation.cginc"

//This file contains the vertex, fragment, and Geometry functions for both the ForwardBase and Forward Add pass.
#if defined(SHADOWS_CUBE) && !defined(SHADOWS_CUBE_IN_DEPTH_TEX)
#define V2F_SHADOW_CASTER_NOPOS float3 vec : TEXCOORD0;
#define TRANSFER_SHADOW_CASTER_NOPOS_GEOMETRY(o,opos) o.vec = mul(unity_ObjectToWorld, v[i].vertex).xyz - _LightPositionRange.xyz; opos = o.pos;
#else
#define V2F_SHADOW_CASTER_NOPOS
#define TRANSFER_SHADOW_CASTER_NOPOS_GEOMETRY(o,opos) \
        opos = UnityClipSpaceShadowCasterPos(v[i].vertex, v[i].normal); \
        opos = UnityApplyLinearShadowBias(opos);
#endif


fixed4 frag (vertexOutput i) : SV_Target
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