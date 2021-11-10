Shader "Unity Shader book/Chapter10/GrabPassShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpTex("Normal map",2D) ="bump" {}

        _Distortion("Distortion",float) = 1.0
        _RefractionAmount("Refraction amount",Range(0,1.0)) = 0.5

        //天空盒子
        _CubeMap("Cube map",Cube) = "_Skybox" {}
    }
    SubShader
    {
        Tags {  
            "RenderType"="Opaque" //shader 替换时候使用
            //Grab pass ：本质是等其他物体全部渲染完了，自己在去grab
            "Queue"="Transparent"

        }

        //带具体名字，只会第一次抓 pass，不带名字每次都会抓

        //next pass can use it
        GrabPass {
            // "_RefractionTex"  //如果不写名字，后续统一用 _GrabTexture
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal:NORMAL;
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;

                //tangent space to world space
                //切线，副切线，法线 ，按照列展开
                fixed4 tangentToWorld0:TEXCOORD1;
                fixed4 tangentToWorld1:TEXCOORD2;
                fixed4 tangentToWorld2:TEXCOORD3;

                fixed4 screenPos:TEXCOORD4; //抓取该pass的值
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _BumpTex;
            float4 _BumpTex_ST;

            float _Distortion;
            float _RefractionAmount;

            //grab pass 用到的
            // sampler2D _RefractionTex;
            // float4 _RefractionTex_TexelSize; //grab 贴图的大小信息等  如书上举的例子:（256,512）对应的就是 (1/256,  1/512) 然后采样贴图

            sampler2D _GrabTexture;
            float4 _GrabTexture_TexelSize;

            samplerCUBE _CubeMap;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //用同一个UV去采样normal 也是可以的
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                //相同的模型UV ，不同的缩放值
                o.uv.zw = TRANSFORM_TEX(v.uv, _BumpTex);


                //切线，副切线，法线的顺序
                fixed3 worldNormal   = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent  = mul(unity_ObjectToWorld,v.tangent).xyz;
                fixed3 worldBiTangent = cross( worldNormal,worldTangent) * v.tangent.w;

                //世界空间的位置
                fixed3 worldPos = mul(unity_ObjectToWorld , v.vertex);

                //还是按照之前的，tangent space to world space  matrix
                o.tangentToWorld0 = fixed4( worldTangent.x,  worldBiTangent.x, worldNormal.x, worldPos.x );
                o.tangentToWorld1 = fixed4( worldTangent.y,  worldBiTangent.y, worldNormal.y, worldPos.y );
                o.tangentToWorld2 = fixed4( worldTangent.z,  worldBiTangent.z, worldNormal.z, worldPos.z );

                //UnityCG.cginc中定义的
                o.screenPos = ComputeGrabScreenPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                fixed4 packedNormal   = tex2D( _BumpTex , i.uv.zw); //

                //正常情况下 x,y,z 就已经存储好了，如果有scale 还要加个norm 做个展开
                fixed3 unpackdNormal = UnpackNormal(packedNormal);

                // float2 offset = unpackdNormal.xy * _Distortion * _RefractionTex_TexelSize.xy;
                float2 offset = unpackdNormal.xy * _Distortion * _GrabTexture_TexelSize.xy;
                i.screenPos.xy = i.screenPos.xy + offset.xy;

            //    fixed3 refractionColor = tex2D( _RefractionTex , i.screenPos.xy).xyz;
               
               fixed3 refractionColor = tex2D( _GrabTexture , i.screenPos.xy).xyz;
                //
                fixed3 worldNormal = normalize(
                    fixed3(
                        dot(i.tangentToWorld0.xyz ,unpackdNormal) ,
                        dot(i.tangentToWorld1.xyz ,unpackdNormal ) ,
                        dot(i.tangentToWorld2.xyz , unpackdNormal) )
                );

                //!x,y,z,w
                fixed3 worldPos  =  fixed3( i.tangentToWorld0.w , i.tangentToWorld1.w, i.tangentToWorld2.w);
                fixed3 worldLightDir  = normalize( UnityWorldSpaceLightDir(worldPos) );
                fixed3 worldViewDir  = normalize(UnityWorldSpaceViewDir(worldPos));

                //获取反射方向
                fixed3 reflectDir = reflect(-worldViewDir,worldNormal);


                fixed4 abedo = tex2D(_MainTex, i.uv.xy);
                fixed3 reflectColor = texCUBE(_CubeMap,reflectDir).xyz * abedo.xyz ;

                //
                // fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * abedo.xyz;
                // fixed3 diffuse = _LightColor0.xyz * ambient.xyz * saturate( dot( worldNormal , worldLightDir ));

                // fixed3 color = fixed3( ambient + diffuse );
                //本质是一个lerp操作
                // fixed3 color =   reflectColor * ( 1 - _RefractionAmount ) + refractionCol * _RefractionAmount;

                fixed3 color = lerp( reflectColor , refractionColor , _RefractionAmount );

                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
}
