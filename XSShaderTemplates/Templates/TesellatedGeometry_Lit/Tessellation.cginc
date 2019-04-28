// Tessellation programs based on this article by Catlike Coding:
// https://catlikecoding.com/unity/tutorials/advanced-rendering/tessellation/

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
    float tessFactor = lerp(1, 0, _TessellationUniform) * 100;
	return edgeLength * _ScreenParams.y / (tessFactor * viewDistance) ;
}

TessellationFactors patchConstantFunction (InputPatch<vertexInput, 3> patch)
{
	TessellationFactors f;

    if(_TessellationMode == 1)
    {
        float3 p0 = mul(unity_ObjectToWorld, patch[0].vertex).xyz;
        float3 p1 = mul(unity_ObjectToWorld, patch[1].vertex).xyz;
        float3 p2 = mul(unity_ObjectToWorld, patch[2].vertex).xyz;

        // float tessFactor = 	
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
        _TessellationUniform *= 100;
        f.edge[0] = _TessellationUniform;
        f.edge[1] = _TessellationUniform;
        f.edge[2] = _TessellationUniform;
        f.inside = _TessellationUniform;
    }
    else
    {
        _TessellationUniform *= 100;
        f.edge[0] = _TessellationUniform;
        f.edge[1] = _TessellationUniform;
        f.edge[2] = _TessellationUniform;
        f.inside = _TessellationUniform;
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