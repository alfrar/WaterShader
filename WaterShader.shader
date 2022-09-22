Shader "Unlit/WaterShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DisTex ("Distortion Texture", 2D) = "white" {}
        [Space(10)]
        _DisSpeed("DIstortion Speed", Range(-0.4,0.4)) = 0.1
        _DisValue("Distortion Value", Range(2,10)) = 3
        [SPace(10)]
        _DepthValue("Depth Value", Range(0,2)) = 1
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }


        // 1. TEXTURE PASS
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
            sampler2D _DisTex;
            float4 _MainTex_ST;
            float _DisSpeed;
            float _DisValue;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed distortion = tex2D(_DisTex, i.uv + (_Time * _DisSpeed)).r;
                i.uv += distortion / _DisValue;
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }

        // 2. DEPTH PASS
        Pass
        {
            Blend OneMinusDstColor One

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
                float4 vertex : SV_POSITION;
                float depth : DEPTH;
            };

            sampler2D _CameraDepthNormalsTexture;
            float _DepthValue;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = ((o.vertex.xy / o.vertex.w) + 1) / 2;
                o.uv.y = 1 - o.uv.y;
                o.depth = -mul(UNITY_MATRIX_MV, v.vertex).z * _ProjectionParams.w;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float screenDepth = DecodeFloatRG(tex2D(_CameraDepthNormalsTexture, i.uv).zw);
                float difference = screenDepth - i.depth;
                float intersection = 0;

                if (difference > 0)
                {
                    intersection = 1 - smoothstep(0, _ProjectionParams.w * _DepthValue, difference);
                }

                return intersection;
            }
            ENDCG
        }
    }
}
