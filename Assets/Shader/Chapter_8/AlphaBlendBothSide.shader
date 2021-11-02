Shader "Unity Shader book/Chapter8/Alpha Blend Both side"
{
    Properties
    {
        _Color("color tint",color) = (1.0,1.0,1.0,1.0)
        _BlendScale("Blend Scale",float) = 1.0

        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { 
            "RenderType"="TransParent" 

            "Queue"="TransParent"
            "IngoreProjector" = "True"
            }


        Pass
        {

            Tags{
                "LightMode"="ForwardBase"
            }
            Cull Front
            ZWrite off //核心是不写入深度值！！！
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

                float3 worldNormal:TEXCOORD1;
                float3 worldPos:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            fixed4 _Color;
            fixed _BlendScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 abedo = tex2D(_MainTex, i.uv);

                fixed3 normal = normalize(i.worldNormal);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * abedo.xyz;
                fixed3 diffuse = _LightColor0.xyz * abedo.xyz * _Color.xyz * saturate(dot(normal,lightDir));

                fixed3 color = ambient + diffuse;

                return fixed4(color, abedo.a * _BlendScale);
            }
            ENDCG
        }



        Pass
        {

            Tags{
                "LightMode"="ForwardBase"
            }
            Cull Back
            ZWrite off //核心是不写入深度值！！！
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

                float3 worldNormal:TEXCOORD1;
                float3 worldPos:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            fixed4 _Color;
            fixed _BlendScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 abedo = tex2D(_MainTex, i.uv);

                fixed3 normal = normalize(i.worldNormal);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * abedo.xyz;
                fixed3 diffuse = _LightColor0.xyz * abedo.xyz * _Color.xyz * saturate(dot(normal,lightDir));

                fixed3 color = ambient + diffuse;

                return fixed4(color, abedo.a * _BlendScale);
            }
            ENDCG
        }
    }
}
