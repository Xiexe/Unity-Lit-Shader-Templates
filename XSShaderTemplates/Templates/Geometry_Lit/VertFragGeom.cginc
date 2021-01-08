//This file contains the vertex, fragment, and Geometry functions for both the ForwardBase and Forward Add pass.
#if defined(SHADOWS_CUBE) && !defined(SHADOWS_CUBE_IN_DEPTH_TEX)
#define V2F_SHADOW_CASTER_NOPOS float3 vec : TEXCOORD0;
#define TRANSFER_SHADOW_CASTER_NOPOS_GEOMETRY(o,opos) o.vec = mul(unity_ObjectToWorld, v[i].vertex).xyz - _LightPositionRange.xyz; opos = o.pos;
#else
#define V2F_SHADOW_CASTER_NOPOS
#define TRANSFER_SHADOW_CASTER_NOPOS_GEOMETRY(o, opos, vertexPosition, vertexNormal) \
        opos = UnityClipSpaceShadowCasterPos(vertexPosition, vertexNormal); \
        opos = UnityApplyLinearShadowBias(opos);
#endif

v2g vert (appdata v)
{
    v2g o = (v2g)0;
    o.vertex = v.vertex;
    o.uv = v.uv;
    
    #if defined(UNITY_PASS_FORWARDBASE)
        o.uv1 = v.uv1;
        o.uv2 = v.uv2;
    #endif
    
    o.normal = v.normal;
    o.tangent = v.tangent;

    return o;
}

[maxvertexcount(3)]
void geom(triangle v2g v[3], inout TriangleStream<g2f> tristream)
{
    g2f o = (g2f)0;

    for (int i = 0; i < 3; i++)
    {
        v[i].vertex.xyz += _VertexOffset * v[i].normal;
        o.pos = UnityObjectToClipPos(v[i].vertex);
        o.uv = TRANSFORM_TEX(v[i].uv, _MainTex);
        #if defined(UNITY_PASS_FORWARDBASE)
            o.uv1 = v[i].uv1;
            o.uv2 = v[i].uv2;
        #endif
        
        //Only pass needed things through for shadow caster
        #if !defined(UNITY_PASS_SHADOWCASTER)
        float3 worldNormal = UnityObjectToWorldNormal(v[i].normal);
        float3 tangent = UnityObjectToWorldDir(v[i].tangent);
        float3 bitangent = cross(tangent, worldNormal) * v[i].tangent.w;

        o.btn[0] = bitangent;
        o.btn[1] = tangent;
        o.btn[2] = worldNormal;
        o.worldPos = mul(unity_ObjectToWorld, v[i].vertex);
        o.objPos = v[i].vertex;
        o.objNormal = v[i].normal;
        UNITY_TRANSFER_SHADOW(o, o.uv);
        #else
        TRANSFER_SHADOW_CASTER_NOPOS_GEOMETRY(o, o.pos, v[i].vertex, v[i].normal);
        #endif
        tristream.Append(o);
    }
    tristream.RestartStrip();
}
			
fixed4 frag (g2f i) : SV_Target
{
        //Return only this if in the shadowcaster
    #if defined(UNITY_PASS_SHADOWCASTER)
        SHADOW_CASTER_FRAGMENT(i);
    #else
        return CustomStandardLightingBRDF(i);
    #endif
}