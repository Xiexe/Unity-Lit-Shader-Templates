struct VertexLightInformation {
    float3 Direction[4];
    float3 ColorFalloff[4];
    float Attenuation[4];
};

sampler2D _MainTex; float4 _MainTex_ST;
sampler2D _MetallicGlossMap;
sampler2D _OcclusionMap;
sampler2D _EmissionMap;
sampler2D _BumpMap;
sampler2D _ClearcoatMap;
sampler2D _CurvatureThicknessMap;
float4 _Color, _EmissionColor, _OcclusionColor, _SubsurfaceScatteringColor;
float _Metallic, _Glossiness, _Reflectance, _Anisotropy;
float _ClearcoatAnisotropy, _Clearcoat, _ClearcoatGlossiness; 
float _BumpScale;
float _Cutoff;
float _SubsurfaceInheritDiffuse, _TransmissionNormalDistortion, _TransmissionPower, _TransmissionScale;

float _VertexOffset;
float _TessellationUniform;
float _TessClose;
float _TessFar;

float _SpecularLMOcclusion, _SpecLMOcclusionAdjust;
float _TriplanarFalloff;
float _LMStrength, _RTLMStrength;

int _TextureSampleMode;
int _LightProbeMethod;
int _TessellationMode;
int _SubsurfaceMethod;