sampler2D _MainTex; float4 _MainTex_ST;
sampler2D _MetallicGlossMap;
sampler2D _BumpMap;
sampler2D _ClearcoatMap;
float4 _Color;
float4 _SubsurfaceColor;
float _Metallic;
float _Glossiness;
float _Reflectance;
float _Clearcoat;
float _ClearcoatGlossiness;
float _BumpScale;

float _VertexOffset;
float _TessellationUniform;
float _TessClose;
float _TessFar;

float _SpecularLMOcclusion;
float _SpecLMOcclusionAdjust;
float _TriplanarFalloff;
float _LMStrength;
float _RTLMStrength;

int _TextureSampleMode;
int _LightProbeMethod;
int _TessellationMode;