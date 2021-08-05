struct VertexLightInformation {
    float3 Direction[4];
    float3 ColorFalloff[4];
    float Attenuation[4];
};

struct LightingVectors
{
    bool lightEnv;
    float3 indirectDominantColor;
    float3 lightDir;
    float3 lightCol;
    float3 viewDir;
    float3 lvHalfVector;
    float3 reflViewDir;
    float3 reflLightDir;
};

struct DotProducts
{
    float rawNdl;   // NormalDir Dot LightDir
    float ndl;      // rawNdl, clamped.
    float ndl01;    // ndl, but remapped to 0-1
    float vdn;      // View Dot Normal
    float vdh;      // View Dot HalfVec
    float rdv;      // ReflLightdir dot View
    float ldh;      // light dot half
    float ndh;      // normal dot half
};

struct NormalData
{
    float3 WorldNormal;
    float3 Tangent;
    float3 Bitangent;
    float3 BumpedWorldNormal;
    float3 BumpedTangent;
    float3 BumpedBitangent;
};

struct FragmentData
{
    float4 Albedo;
    float4 Normal;
    float3 Emission;
    float3 SubsurfaceColor;
    float Metallic;
    float Reflectance;
    float Smoothness;
    float Occlusion;
    float Curvature;
    float Thickness;
    float SubsurfaceTransmissionMask;
    float Alpha;

    float ClearcoatSmoothness;
    float ClearcoatReflectance;
};

sampler2D _MainTex; float4 _MainTex_ST;
sampler2D _MetallicGlossMap; float4 _MetallicGlossMap_ST;
sampler2D _OcclusionMap; float4 _OcclusionMap_ST;
sampler2D _EmissionMap; float4 _EmissionMap_ST;
sampler2D _BumpMap; float4 _BumpMap_ST;
sampler2D _ClearcoatMap; float4 _ClearcoatMap_ST;
sampler2D _CurvatureThicknessMap; float4 _CurvatureThicknessMap_ST;
sampler2D _SubsurfaceColorMap; float4 _SubsurfaceColorMap_ST;

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