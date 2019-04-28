// Tessellation programs based on this article by Catlike Coding:
// https://catlikecoding.com/unity/tutorials/advanced-rendering/tessellation/

float UnityDistanceFromPlane (float3 pos, float4 plane)
{
    float d = dot (float4(pos,1.0f), plane);
    return d;
}

// Returns true if triangle with given 3 world positions is outside of camera's view frustum.
// cullEps is distance outside of frustum that is still considered to be inside (i.e. max displacement)
bool UnityWorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps)
{
    float4 planeTest;

    // left
    planeTest.x = (( UnityDistanceFromPlane(wpos0, unity_CameraWorldClipPlanes[0]) > -cullEps) ? 1.0f : 0.0f ) +
                  (( UnityDistanceFromPlane(wpos1, unity_CameraWorldClipPlanes[0]) > -cullEps) ? 1.0f : 0.0f ) +
                  (( UnityDistanceFromPlane(wpos2, unity_CameraWorldClipPlanes[0]) > -cullEps) ? 1.0f : 0.0f );
    // right
    planeTest.y = (( UnityDistanceFromPlane(wpos0, unity_CameraWorldClipPlanes[1]) > -cullEps) ? 1.0f : 0.0f ) +
                  (( UnityDistanceFromPlane(wpos1, unity_CameraWorldClipPlanes[1]) > -cullEps) ? 1.0f : 0.0f ) +
                  (( UnityDistanceFromPlane(wpos2, unity_CameraWorldClipPlanes[1]) > -cullEps) ? 1.0f : 0.0f );
    // top
    planeTest.z = (( UnityDistanceFromPlane(wpos0, unity_CameraWorldClipPlanes[2]) > -cullEps) ? 1.0f : 0.0f ) +
                  (( UnityDistanceFromPlane(wpos1, unity_CameraWorldClipPlanes[2]) > -cullEps) ? 1.0f : 0.0f ) +
                  (( UnityDistanceFromPlane(wpos2, unity_CameraWorldClipPlanes[2]) > -cullEps) ? 1.0f : 0.0f );
    // bottom
    planeTest.w = (( UnityDistanceFromPlane(wpos0, unity_CameraWorldClipPlanes[3]) > -cullEps) ? 1.0f : 0.0f ) +
                  (( UnityDistanceFromPlane(wpos1, unity_CameraWorldClipPlanes[3]) > -cullEps) ? 1.0f : 0.0f ) +
                  (( UnityDistanceFromPlane(wpos2, unity_CameraWorldClipPlanes[3]) > -cullEps) ? 1.0f : 0.0f );

    // has to pass all 4 plane tests to be visible
    return !all (planeTest);
}

struct TessellationFactors 
{
	float edge[3] : SV_TessFactor;
	float inside : SV_InsideTessFactor;
};

vertexInput vert(vertexInput v)
{
	return v;
}

vertexOutput tessVert(vertexInput v)
{
	return v;
}

float TessEdgeFactor(float3 p0, float3 p1)
{
	float edgeLength = distance(p0, p1);

	float3 edgeCenter = (p0 + p1) * 0.5;
	float viewDistance = distance(edgeCenter, _WorldSpaceCameraPos);
    float tessFactor = lerp(1, 0, _TessellationUniform) * 50;
	return edgeLength * _ScreenParams.y / (tessFactor * viewDistance) ;
}

TessellationFactors patchConstantFunction (InputPatch<vertexInput, 3> patch)
{
	TessellationFactors f;
    float3 p0 = mul(unity_ObjectToWorld, patch[0].vertex).xyz;
    float3 p1 = mul(unity_ObjectToWorld, patch[1].vertex).xyz;
    float3 p2 = mul(unity_ObjectToWorld, patch[2].vertex).xyz;
    float bias = 0;
    

    if(UnityWorldViewFrustumCull(p0, p1, p2, bias))
    {
        f.edge[0] = f.edge[1] = f.edge[2] = f.inside = 0;
    }
    else
    {
        if(_TessellationMode == 1)
        {
            f.edge[0] = TessEdgeFactor(p1, p2);
            f.edge[1] = TessEdgeFactor(p2, p0);
            f.edge[2] = TessEdgeFactor(p0, p1);
            f.inside =
                (TessEdgeFactor(p1, p2) +
                TessEdgeFactor(p2, p0) +
                TessEdgeFactor(p0, p1)) * (1 / 3.0);
        }
        else if(_TessellationMode == 0)
        {
            _TessellationUniform *= 50;
            f.edge[0] = _TessellationUniform;
            f.edge[1] = _TessellationUniform;
            f.edge[2] = _TessellationUniform;
            f.inside = _TessellationUniform;
        }
        else
        {
            _TessellationUniform *= 50;
            f.edge[0] = _TessellationUniform;
            f.edge[1] = _TessellationUniform;
            f.edge[2] = _TessellationUniform;
            f.inside = _TessellationUniform;
        }
    }


    return f;
}

[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("fractional_odd")]
//[UNITY_partitioning("integer")]
[UNITY_patchconstantfunc("patchConstantFunction")]
vertexInput hull (InputPatch<vertexInput, 3> patch, uint id : SV_OutputControlPointID)
{
	return patch[id];
}

[UNITY_domain("tri")]
vertexOutput domain(TessellationFactors factors, OutputPatch<vertexInput, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
{
	vertexInput v;

	#define DOMAIN_INTERPOLATE(fieldName) v.fieldName = \
		patch[0].fieldName * barycentricCoordinates.x + \
		patch[1].fieldName * barycentricCoordinates.y + \
		patch[2].fieldName * barycentricCoordinates.z;

	DOMAIN_INTERPOLATE(vertex)
    DOMAIN_INTERPOLATE(uv)
	DOMAIN_INTERPOLATE(normal)
	DOMAIN_INTERPOLATE(tangent)
    

	return tessVert(v);
}