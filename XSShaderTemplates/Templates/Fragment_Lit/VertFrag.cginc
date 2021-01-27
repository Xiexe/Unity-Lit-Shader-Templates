//This file contains the vertex and fragment functions for both the ForwardBase and Forward Add pass.

v2f vert (appdata v)
{
    v2f o;
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
        float4 albedo = texTP(_MainTex, _MainTex_ST, i.worldPos, i.objPos, i.btn[2], i.objNormal, _TriplanarFalloff, i.uv) * _Color;
        float alpha;
        doAlpha(alpha, albedo.a, i.screenPos);
        SHADOW_CASTER_FRAGMENT(i);
    #else
        return CustomStandardLightingBRDF(i);
    #endif
}