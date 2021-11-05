// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "Unity Shader book/Chapter9/Shadow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color Tint",color) = (1.0,1.0,1.0,1.0)

        _Specular("Specular",color) = (1.0,1.0,1.0,1.0)
        _Gloss("Gloss",range(20.0,240)) = 20
    }
    SubShader
    {
        Tags { 
                "RenderType"="Opaque"
             }
        Pass
        {
            Tags{
                "LightMode"="ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION; //a2v 一定有vertex
                float2 uv : TEXCOORD0;
                float4 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION; //v2f一定要有pos

                float3 worldPos:TEXCOORD1;
                float3 worldNormal:TEXCOORD2;

                SHADOW_COORDS(3)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            fixed _Gloss;
            fixed4 _Specular;
            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex); // *xy + zw

                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                //正常变换的逆转矩阵
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                fixed4 abedo = fixed4(1.0,1.0,1.0,1.0);//tex2D(_MainTex, i.uv);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * abedo.xyz;

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 lightDir = normalize( UnityWorldSpaceLightDir(i.worldPos));
                fixed3 viewDir =normalize(UnityWorldSpaceViewDir(i.worldPos));

                fixed3 halfVector = normalize(lightDir + viewDir);

                //有个LightColor0,有个LightTexture0 光照衰减的
                fixed3 diffuse =  _Color.xyz * abedo.xyz * _LightColor0.xyz * saturate(dot(worldNormal,lightDir));
                fixed3 specular = _Specular.xyz * _LightColor0.xyz * pow(saturate(dot(worldNormal,halfVector)),_Gloss);

                //需要考虑一个衰减， base中只计算了direct 光，所以衰减为1
                fixed atten = 1;


                fixed shadow = SHADOW_ATTENUATION(i);
                fixed3 color =  (diffuse + specular ) * atten * shadow + ambient;

                return fixed4(color,1.0);
            }
            ENDCG
        }


        pass
        {
            Tags {
                "LightMode"="ForwardAdd"
            }

            //线性减淡
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd


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
                float4 vertex : SV_POSITION;

                float3 worldPos:TEXCOORD1;
                float3 worldNormal:TEXCOORD2;

            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            fixed _Gloss;
            fixed4 _Specular;
            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex); // *xy + zw

                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                //正常变换的逆转矩阵
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                fixed4 abedo = tex2D(_MainTex, i.uv);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * abedo.xyz;

                fixed3 worldNormal = normalize(i.worldNormal);

                //最好这里还是用直接WorldPos0吧，因为当前逐像素shading的
                #ifdef USING_DIRECTIONAL_LIGHT
                    //平行光
                    fixed3 lightDir = normalize( _WorldSpaceLightPos0 );//- i.worldPos;
                #else
                    fixed3 lightDir = normalize( _WorldSpaceLightPos0- i.worldPos );
                #endif

                //
                // fixed3 lightDir = normalize( UnityWorldSpaceLightDir(i.worldPos));
                fixed3 viewDir =normalize(UnityWorldSpaceViewDir(i.worldPos));

                fixed3 halfVector = normalize(lightDir + viewDir);

                //有个LightColor0,有个LightTexture0 光照衰减的
                fixed3 diffuse =  _Color.xyz * abedo.xyz * _LightColor0.xyz * saturate(dot(worldNormal,lightDir));
                fixed3 specular = _Specular.xyz * _LightColor0.xyz * pow(saturate(dot(worldNormal,halfVector)),_Gloss);

                //需要考虑一个衰减， base中只计算了direct 光，所以衰减为1

                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed atten = 1;
                #else
                    float3 lightCoord = mul( unity_WorldToLight ,float4( i.worldPos , 1.0 )).xyz;
                    fixed atten = tex2D(_LightTexture0, dot(lightCoord,lightCoord).rr ).UNITY_ATTEN_CHANNEL;
                #endif

                fixed3 color =  (diffuse + specular ) * atten ;

                return fixed4(color,1.0);
            }



            ENDCG

        }


    }


    FallBack "VertexLit"


}
