//This file contains all of the neccisary functions for lighting to work a'la standard shading.
//Feel free to add to this.

half4 getMetallicSmoothness(float4 metallicGlossMap)
{
	half roughness = 1-(_Glossiness * metallicGlossMap.a);
	roughness *= 1.7 - 0.7 * roughness;
	half metallic = metallicGlossMap.r * _Metallic;
	return half4(metallic, 0, 0, roughness);
}

//Reflection direction, worldPos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
float3 getReflectionUV(float3 direction, float3 position, float4 cubemapPosition, float3 boxMin, float3 boxMax) 
{
	#if UNITY_SPECCUBE_BOX_PROJECTION
		if (cubemapPosition.w > 0) {
			float3 factors = ((direction > 0 ? boxMax : boxMin) - position) / direction;
			float scalar = min(min(factors.x, factors.y), factors.z);
			direction = direction * scalar + (position - cubemapPosition);
		}
	#endif
	return direction;
}

half3 getIndirectSpecular(float3 worldPos, float3 diffuseColor, float vdn, float4 metallicSmoothness, half3 reflDir, half3 indirectLight, float3 viewDir, float3 lighting)
{	//This function handls Unity style reflections, Matcaps, and a baked in fallback cubemap.
		half3 spec = half3(0,0,0);
        float3 reflectionUV1 = getReflectionUV(reflDir, worldPos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
        half4 probe0 = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionUV1, metallicSmoothness.w * 6);
        half3 probe0sample = DecodeHDR(probe0, unity_SpecCube0_HDR);

        float3 indirectSpecular;
        float interpolator = unity_SpecCube0_BoxMin.w;
        
        UNITY_BRANCH
        if (interpolator < 0.99999) 
        {
            float3 reflectionUV2 = getReflectionUV(reflDir, worldPos, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
            half4 probe1 = UNITY_SAMPLE_TEXCUBE_SAMPLER_LOD(unity_SpecCube1, unity_SpecCube0, reflectionUV2, metallicSmoothness.w * 6);
            half3 probe1sample = DecodeHDR(probe1, unity_SpecCube1_HDR);
            indirectSpecular = lerp(probe1sample, probe0sample, interpolator);
        }
        else 
        {
            indirectSpecular = probe0sample;
        }

        half3 metallicColor = indirectSpecular * lerp(0.05,diffuseColor.rgb, metallicSmoothness.x);
        spec = lerp(indirectSpecular, metallicColor, pow(vdn, 0.05));
		spec = lerp(spec, spec * lighting, metallicSmoothness.w); // should only not see shadows on a perfect mirror.
	return spec;
}

half3 getDirectSpecular(half4 lightCol, half3 diffuseColor, half4 metallicSmoothness, float rdv, float atten)
{	
	half smoothness = max(0.0001, 1-metallicSmoothness.w);
	smoothness *= 1.7 - 0.7 * smoothness;
	
    half3 specularReflection = saturate(pow(rdv, smoothness * 128)) * lightCol;
	specularReflection = lerp(specularReflection, specularReflection * diffuseColor, metallicSmoothness.x);

    specularReflection *= smoothness;
    specularReflection *= 5; //Artificially brighten to be as bright as standard
    return specularReflection * atten;
}

float3 getNormal(float4 normalMap, float3 bitangent, float3 tangent, float3 worldNormal)
{
    half3 tspace0 = half3(tangent.x, bitangent.x, worldNormal.x);
	half3 tspace1 = half3(tangent.y, bitangent.y, worldNormal.y);
	half3 tspace2 = half3(tangent.z, bitangent.z, worldNormal.z);

	half3 nMap = UnpackNormal(normalMap);
	nMap.xy *= _BumpScale;

	half3 calcedNormal;
	calcedNormal.x = dot(tspace0, nMap);
	calcedNormal.y = dot(tspace1, nMap);
	calcedNormal.z = dot(tspace2, nMap);
	
	calcedNormal = normalize(calcedNormal);
    return calcedNormal;
}

half3 getLightDir(float3 worldPos)
{
	half3 lightDir = UnityWorldSpaceLightDir(worldPos);
    
	half3 probeLightDir = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz;
	lightDir = (lightDir + probeLightDir); //Make light dir the average of the probe direction and the light source direction.

		#if !defined(POINT) && !defined(SPOT) // if the average length of the light probes is null, and we don't have a directional light in the scene, fall back to our fallback lightDir
			if(length(unity_SHAr.xyz*unity_SHAr.w + unity_SHAg.xyz*unity_SHAg.w + unity_SHAb.xyz*unity_SHAb.w) == 0 && ((_LightColor0.r+_LightColor0.g+_LightColor0.b) / 3) < 0.1)
			{
				lightDir = float4(1, 1, 1, 0);
			}
		#endif

	return normalize(lightDir);
}