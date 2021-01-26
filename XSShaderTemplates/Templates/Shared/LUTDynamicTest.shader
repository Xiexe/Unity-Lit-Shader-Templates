Shader "Unlit/LUTDynamicTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 col = 0;
                float mod = smoothstep(0, 1, i.uv.y);
                float mod2 = smoothstep(0, 1, i.uv.x);
                float mod3 = smoothstep(0.4, 1, i.uv.x);
                float ndl = smoothstep(0.5, 0.6, i.uv.x);
                float curvature = ((mod * mod2) + mod3 + (mod * 0.05) + ndl) / 3;
                float colorBlend = smoothstep(1, 0, i.uv.x);
                return curvature * lerp(1, _Color, colorBlend);
                
                return 1;
            }
            ENDCG
        }
    }
}
