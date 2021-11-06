Shader "Unity Shader book/Chapter9/AlphaBlendWithShadow" 
//alpha blend 有几个要点，
//本质是      1. 在不透明物体之后渲染的， 关闭深度写入，取framebuffer 原来的值 和自身SrcXXX 做个混合相加,
//           2. Blend 相关命令  如正片叠底，线性减淡
//           3. 实际采样了贴图的 a 通道的值了
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color tint",color)  = (1.0, 1.0, 1.0, 1.0)
        _Specular("Specular",color) = (1.0, 1.0, 1.0, 1.0)
        _Gloss("Gloss",range(20.0, 240)) = 20
    }
    SubShader
    {
        Tags {
                "RenderType" = "Transparent" 
                "Queue" = "Alphatest"
                "IgnoreProjector" = "True"
            }

        Pass
        {
            Tags{

                "LightMode"="ForwardBase"
            }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase


            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "AutoLight.cginc"


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                // UNITY_FOG_COORDS(1) 也是从1 开始的，本质两者是相同的
                float4 pos : SV_POSITION;
                float3 worldPos:TEXCOORD1;
                float3 worldNormal:TEXCOORD2;

                SHADOW_COORDS(3)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _Color;
            float4 _Specular;
            float _Gloss;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                // TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 abedo = tex2D(_MainTex, i.uv);

                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 normalDir = normalize(i.worldNormal);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * abedo.xyz;
                fixed3 diffuse =  abedo.xyz * _LightColor0.xyz * _Color.xyz * saturate(dot(normalDir,lightDir));


                fixed3 viewDir = normalize( UnityWorldSpaceViewDir(i.worldPos) ) ;
                fixed3 halfVector = normalize(viewDir + lightDir);

                // fixed3 specular = _Specular.xyz * _LightColor0.xyz * pow(max(0,dot( normalDir ,halfVector )  ) ,_Gloss);

                UNITY_LIGHT_ATTENUATION(atten, i , i.worldPos);
                fixed3 color =  ambient + (diffuse ) * atten;


                return fixed4(color,abedo.a);
            }
            ENDCG
        }
    }

    // FallBack "Transparent/VertexLit" 透明物体自身并没包含阴影投射信息
    FallBack "VertexLit"
}
