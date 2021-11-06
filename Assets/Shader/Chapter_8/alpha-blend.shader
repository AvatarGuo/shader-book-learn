Shader "Unity Shader book/Chapter8/Alpha blend"
{
    Properties
    {
        _Color("Color tine",color) = (1.0, 1.0, 1.0, 1.0)
        _MainTex ("Texture", 2D) = "white" {}
        _AlphaScale("alpha scale",float) = 1.0
    }
    SubShader
    {
        Tags {
                "RenderType"="TransParent" //unity中将渲染模式进行一个分组（通常用于被着色器替换功能）

                "Queue"="TransParent"
                "IgnoreProjector" = "True"
            }

        Pass
        {

            Tags
            {
                "LightingMode"= "ForwardBase"
            }

            // ZWrite off
            // Blend SrcAlpha OneMinusSrcAlpha

            ZWrite off
            Blend SrcAlpha OneMinusSrcAlpha

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

                fixed3 worldPos:TEXCOORD1;
                fixed3 worldNormal:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;


            fixed4 _Color;
            fixed _AlphaScale;

            v2f vert ( appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                fixed3 normal = normalize(i.worldNormal);
                fixed3 lightDir = normalize( UnityWorldSpaceLightDir(i.worldPos));
                //specular 采用view dir
                // fixed3 viewDir  = normalize( UnityWorldSpaceViewDir(i.worldPos) ); //获得视角方向

                fixed4 abedo = tex2D(_MainTex, i.uv);
                // clip(abedo.a - _AlphaScale);
                fixed3 lightColor = _LightColor0.xyz;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * abedo.xyz;
                fixed3 diffuse = _Color.rgb * lightColor * abedo.xyz * saturate(dot(normal,lightDir));


                fixed3 color = ambient + diffuse;
                return fixed4(color , abedo.a * _AlphaScale );
            }
            ENDCG
        }
    }
}
