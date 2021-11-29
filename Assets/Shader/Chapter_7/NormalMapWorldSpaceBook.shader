Shader "Unity Shader book/Chapter7/NormalMapWorldSpaceBook"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _Diffuse("diffuse",color) = ( 1.0 , 1.0 ,1.0 ,1.0)

        _Specular("specular",color) = ( 1.0, 1.0, 1.0, 1.0)

        _Gloss("gloss",Range(20,240)) = 20.0
        //
        _BumpTex("Normal Map",2D) = "bump" {}
        _BumpScale("Bump Scale" ,Float) = 1.0

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

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

                //
                float4 tangent:TANGENT;
                float4 normal:NORMAL;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;

                //vs端算好矩阵，传给ps端，注意也是不能归一化，三个轴
                //tangent to world matrix
                //算出tangent 在world 下表示的xyz 轴， tangent->world是列排列矩阵，因为正交矩阵，所以world->tangent 是三个轴横过来 章节p 4.6.2
                float4 T2W0:TEXCOORD1;
                float4 T2W1:TEXCOORD2;
                float4 T2W2:TEXCOORD3;


                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            //
            sampler2D _BumpTex;
            float4 _BumpTex_ST;
            float _BumpScale;

            float4 _Diffuse;
            float4 _Specular;
            float _Gloss;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                //
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _BumpTex);

                //切线，副切线，法线 坐标轴
                float3 worldTangent     = UnityObjectToWorldDir( v.tangent.xyz );
                float3 worldNormal      = UnityObjectToWorldNormal( v.normal.xyz ); 
                //这里其实有个问题，两个世界坐标的叉乘，乘以一个模型空间的w
                float3 worldBinormal    = cross( worldNormal , worldTangent ) * v.tangent.w;

                float3 worldPos = mul( (float3x3) unity_ObjectToWorld , v.vertex);

                //世界转world

                //分别对应x轴，和 y轴 和 z轴 ，world2this
                o.T2W0 = float4(worldTangent.x , worldBinormal.x , worldNormal.x , worldPos.x );
                o.T2W1 = float4(worldTangent.y , worldBinormal.y , worldNormal.y , worldPos.y );
                o.T2W2 = float4(worldTangent.z , worldBinormal.z , worldNormal.z , worldPos.z );

      

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 abedo  = tex2D(_MainTex, i.uv.xy);

                //pack normal 
                fixed4 packNormal       =   tex2D( _BumpTex , i.uv.zw); 
                fixed3 tangentNormal    =   UnpackNormal(packNormal );
                tangentNormal.xy        *=  _BumpScale;
                tangentNormal.z         = sqrt( 1.0 -  saturate ( dot (tangentNormal.xy , tangentNormal.xy  ) )) ;


                //存储到切线空间中可压缩
                fixed3 worldNormal = normalize( fixed3( dot(i.T2W0.xyz,tangentNormal) , dot(i.T2W1.xyz , tangentNormal ),dot(i.T2W2.xyz ,tangentNormal)) );
                fixed3 worldPos = fixed3(i.T2W0.z , i.T2W1.z , i.T2W2.z  );

                fixed3 lightDir = normalize( UnityWorldSpaceLightDir(worldPos) );
                fixed3 viewDir  = normalize( UnityWorldSpaceViewDir(worldPos) );

                fixed3 halfVector = normalize( lightDir + viewDir);

                //
                fixed3 lightColor = _LightColor0.xyz;

                //ambient ,max ,specular 
                fixed3 ambient  = UNITY_LIGHTMODEL_AMBIENT.xyz * abedo ;
                fixed3 diffuse  = lightColor * _Diffuse.xyz * abedo * max(0 , dot( worldNormal , lightDir ));
                fixed3 specular = lightColor * _Specular.xyz * pow( max( 0 ,  dot(worldNormal,halfVector)) ,_Gloss);

                //对于specular 贴图来说的话 做个处理。
                fixed3 color = ambient + diffuse + specular;

                return fixed4(color , 1.0 );

            }
            ENDCG
        }
    }
}
