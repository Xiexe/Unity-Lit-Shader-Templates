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

float UnityCalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess)
{
    float3 wpos = vertex.xyz;
    float dist = distance (wpos, _WorldSpaceCameraPos);
    float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
    return f;
}

float4 UnityCalcTriEdgeTessFactors (float3 triVertexFactors)
{
    float4 tess;
    tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
    tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
    tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
    tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
    return tess;
}

// Distance based tessellation:
// Tessellation level is "tess" before "minDist" from camera, and linearly decreases to 1
// up to "maxDist" from camera.
float4 UnityDistanceBasedTess (float4 v0, float4 v1, float4 v2, float minDist, float maxDist, float tess)
{
    float3 f;
    f.x = UnityCalcDistanceTessFactor (v0,minDist,maxDist,tess);
    f.y = UnityCalcDistanceTessFactor (v1,minDist,maxDist,tess);
    f.z = UnityCalcDistanceTessFactor (v2,minDist,maxDist,tess);

    return UnityCalcTriEdgeTessFactors (f);
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
    float4 p0 = mul(unity_ObjectToWorld, patch[0].vertex);
    float4 p1 = mul(unity_ObjectToWorld, patch[1].vertex);
    float4 p2 = mul(unity_ObjectToWorld, patch[2].vertex);
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
            float4 distanceTess = UnityDistanceBasedTess(p0, p1, p2, _TessClose, _TessFar, _TessellationUniform);
            f.edge[0] = distanceTess;
            f.edge[1] = distanceTess;
            f.edge[2] = distanceTess;
            f.inside = distanceTess;
        }
    }
    return f;
}

[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("fractional_odd")]
//[UNITY_partitioning("fractional_even")]
//[UNITY_partitioning("pow2")]
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
    #if defined(UNITY_PASS_FORWARDBASE)
        DOMAIN_INTERPOLATE(uv1)
        DOMAIN_INTERPOLATE(uv2)
    #endif
	DOMAIN_INTERPOLATE(normal)
	DOMAIN_INTERPOLATE(tangent)

	return tessVert(v);
}