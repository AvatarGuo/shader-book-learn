Shader "Unity Shader book/Chapter8/Alpha Test Both side"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color tint",color) = (1.0,1.0,1.0,1.0)
        _ClipScale("cut scale",Range(0,1.0)) = 0.5
    }
    SubShader
    {
        Tags {
                "RenderType"="TransParentCutout" 

                "Queue" = "AlphaTest"
                "IgnoreProjector" = "True"
            }


        Pass
        {

            Tags {
                "LightMode" = "ForwardBase"
            }

            Cull off //

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;

                float4 vertex : SV_POSITION;
                fixed4 worldPos:TEXCOORD1;
                fixed3 worldNormal:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            fixed4 _Color;
            fixed _ClipScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldNormal  = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                fixed3 normal  = normalize(i.worldNormal.xyz);
                fixed3 lightDir =normalize(UnityWorldSpaceLightDir(i.worldPos));



                fixed4 abedo = tex2D(_MainTex, i.uv);

                clip(abedo.a - _ClipScale);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * abedo.xyz;
                fixed3 diffuse = _LightColor0.xyz * _Color.xyz * abedo.xyz * saturate(dot( normal,lightDir ));

                fixed3 color = ambient + diffuse;

                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
}
