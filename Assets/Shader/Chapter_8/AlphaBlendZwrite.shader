Shader "Unity Shader book/Chapter8/Alpha blend ZWrite"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("color tint",color) = ( 1.0, 1.0, 1.0, 1.0)
        _AlphaScale("alpha scale",float) = 1.0
    }
    //类似techniques ，找到最符合的那个Subshader
    SubShader
    {
        Tags {
            "RenderType"="TransParent"

            "Queue" = "TransParent"
            "IgnoreProjector" = "True"
        }

        //一个空pass，会跑出来全白的场景
        pass
        {
            ZWrite on
            ColorMask 0


        }


        Pass
        {
            ZWrite off
            Blend SrcAlpha OneMinusSrcAlpha

            Tags {
                "LightMode"="ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                float4 tangent:TANGENT;
                float4 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;

                float4 vertex : SV_POSITION;

                fixed3 worldNormal:TEXCOORD1;
                fixed3 worldPos:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;


            fixed4 _Color;
            fixed _AlphaScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 abedo = tex2D(_MainTex, i.uv);

                fixed3 normal  = normalize(i.worldNormal);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz  * abedo.xyz;
                fixed3 diffuse = _LightColor0.xyz * abedo.xyz * _Color.xyz  * saturate(dot(normal,lightDir));

                fixed3 color = ambient+diffuse;
                return fixed4(color, abedo.a);
            }
            ENDCG
        }

    }
}
