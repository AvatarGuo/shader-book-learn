﻿Shader "Unlit/testMat"
{
Properties
    {


        _Color("color tint" ,color) = (1.0 , 1.0 ,1.0 , 1.0)

        _Specular("Specular",color) = (1.0 , 1.0 ,1.0 , 1.0)
        _Gloss("gloss",range(20.0,240))=20

        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags {
                "RenderType"="Opaque"
             }

        Pass
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }


            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                float4 normal:NORMAL;

            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 worldPos:TEXCOORD1;
                float3 worldNormal:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Gloss;
            float4 _Color;
            float4 _Specular;


            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 abedo = tex2D(_MainTex, i.uv);


                fixed3 worldNormal = normalize(i.worldNormal);

                fixed3 lightDir = normalize( UnityWorldSpaceLightDir(i.worldPos)  );
                fixed3 viewDir  = normalize( UnityWorldSpaceViewDir( i.worldPos ) );

                fixed3 halfVector = normalize( lightDir +  viewDir);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * abedo.xyz ;

                fixed3 diffuse = abedo.xyz * _LightColor0.xyz * _Color.xyz *  saturate( dot( worldNormal , lightDir ));
                fixed3 specular = _Specular.xyz * _LightColor0.xyz * pow(saturate( dot(worldNormal,halfVector) ), _Gloss);


                fixed3 color = ambient + diffuse;


                return fixed4( color , 1.0 );
            }
            ENDCG
        }
    }

    FallBack "Transparent/Cutout/VertexLit"
}
