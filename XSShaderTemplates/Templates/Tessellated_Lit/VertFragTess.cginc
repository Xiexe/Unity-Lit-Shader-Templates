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
        float4 albedo = texTP(_MainTex, _MainTex_ST, i.worldPos, i.objPos, i.btn[2], i.objNormal, _TriplanarFalloff, i.uv) * _Color;
        float alpha;
        doAlpha(alpha, albedo.a, i.screenPos);
        SHADOW_CASTER_FRAGMENT(i);
    #else
        return CustomStandardLightingBRDF(i);
    #endif
}