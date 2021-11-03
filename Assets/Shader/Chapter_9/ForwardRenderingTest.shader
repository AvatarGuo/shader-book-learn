// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "Unity Shader book/Chapter9/Forward Rendering"
{
    Properties
    {
        _MainTex ("Texture", 2D)    = "white" {}
        _Color("Color tint",color)  = (1.0 , 1.0 , 1.0 , 1.0)

        _Specular("Specular",color) = (1.0,1.0,1.0,1.0)
        _Gloss("Gloss",range(20.0,240)) = 20
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Tags{

                //写错了 是LightMode
                "LightMode"="ForwardBase"
            }

            CGPROGRAM


            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            #pragma multi_compile_fwdbase

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

            float _Gloss;
            fixed4 _Specular;
            fixed4 _Color;

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

                fixed4 abedo = tex2D(_MainTex, i.uv);

                fixed3 ambient  = UNITY_LIGHTMODEL_AMBIENT.xyz * abedo.xyz ;

                fixed3 normal = normalize(i.worldNormal);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos ));
                fixed3 viewDir  = normalize(UnityWorldSpaceViewDir(i.worldPos));

                fixed3 halfVector = normalize(lightDir + viewDir); //差点忘了 half vector

                // fixed3 diffuse  = _Color.rgb * abedo.xyz * _LightColor0.xyz * saturate(dot(normal,lightDir));
                fixed3 diffuse  = _Color.rgb * abedo.xyz * _LightColor0.xyz * saturate(dot(normal,lightDir));
                fixed3 specular =  _LightColor0.xyz * _Specular.xyz * pow(saturate(dot(normal,halfVector)) ,_Gloss);

                fixed   atten = 1.0; //衰减系数  ，因为base pass ，只处理最重要的平行光，所以这里设置 1.0
                fixed3  color = ambient + ( diffuse + specular ) * atten;

                return fixed4(color ,1.0);
            }
            ENDCG
        }


        Pass{
            Tags{
                "LightMode"="ForwardAdd"
            }

            //线性减淡效果,可以选择多种混合模式
            Blend one one

            CGPROGRAM

            #pragma multi_compile_fwdadd

            #pragma vertex      vert
            #pragma fragment    frag


            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "AutoLight.cginc"  //需要导入AutoLight.cginc

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

            float _Gloss;
            fixed4 _Specular;
            fixed4 _Color;

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

                fixed4 abedo = tex2D(_MainTex, i.uv);

                // fixed3 ambient  = UNITY_LIGHTMODEL_AMBIENT.xyz * abedo.xyz ;

                fixed3 normal = normalize(i.worldNormal);

                #ifdef USING_DIRECTIONAL_lIGHT
                    fixed3 lightDir = normalize( _WorldSpaceLightPos0.xyz ) ;
                #else
                    fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos );
                #endif


                // fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos ));
                fixed3 viewDir  = normalize(UnityWorldSpaceViewDir(i.worldPos));

                fixed3 halfVector = normalize(lightDir + viewDir); //差点忘了 half vector


                fixed3 diffuse  = _Color.rgb * abedo.xyz * _LightColor0.xyz * saturate(dot(normal,lightDir));
                fixed3 specular =  _LightColor0.xyz * _Specular.xyz * pow(saturate(dot(normal,halfVector)) ,_Gloss);


                #ifdef USING_DIRECTIONAL_lIGHT
                    fixed atten = 1.0;
                #else

                    //unity这里使用了一个LUT 查找表去计算光照衰减的
                    //一般衰减系数是距离的平方，球面衰减系数

                    //先求出在光源空间下的坐标
                    fixed3 lightCoord = mul(unity_WorldToLight,float4(i.worldPos,1.0)).xyz;
                    fixed  atten = tex2D( _LightTexture0 ,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;

                    #if defined (POINT)
				        float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
				        fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				    #elif defined (SPOT)
				        float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
				        fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				    #else
				        fixed atten = 1.0;
				    #endif


                #endif

                // fixed   atten = 1.0; //衰减系数  ，因为base pass ，只处理最重要的平行光，所以这里设置 1.0
                fixed3  color =    (diffuse + specular)  * atten;

                return fixed4(color ,1.0);
            }


            ENDCG

        }
    }
}
