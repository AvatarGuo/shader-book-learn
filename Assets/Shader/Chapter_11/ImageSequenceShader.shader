
Shader "Unity Shader book/Chapter11/ImageSequenceShader"
{
    Properties
    {
        _Color("color tint",color) = (1.0, 1.0, 1.0, 1.0)
        _MainTex ("Texture", 2D) = "white" {}

        _HorizontalAmont("horizontal amont",float) = 4
        _VerticalAmont("vertical amont",float) = 4

        _Speed("speed",range(1,100)) = 20
    }
    SubShader
    {
        Tags {
                "RenderType" = "Transparent"
                "Queue" = "Transparent"
                "IgnoreProjector" = "True"
            }

        Pass
        {
            Tags {
                "LightMode"="ForwardBase"
            }

            ZWrite off
            Blend  SrcAlpha  OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag



            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "UnityLightingCommon.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            fixed4 _Color;
            fixed _Speed;
            fixed _HorizontalAmont;
            fixed _VerticalAmont;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float time = floor( _Time.y * _Speed );

                float row  = floor(time/_HorizontalAmont);
                float col  = time - row * _HorizontalAmont;

                //最小单位的uv，然后做个偏移计算即可。
                //uv 1,1,是最大的那个

                half2 uv = float2(  i.uv.x / _HorizontalAmont,  i.uv.y / _VerticalAmont);
                uv.x += col / _HorizontalAmont;
    
                uv.y -= row / _VerticalAmont;


                fixed4 abedo = tex2D(_MainTex, uv);
                abedo.rgb *= _Color;

                return abedo;
            }
            ENDCG
        }
    }
}
