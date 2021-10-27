//重新写一遍从tangent空间转世界空间计算法线光线的方法
Shader "Unity Shader book/Chapter7/NormalMapWorldSpace2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpTex("Normal map",2D) = "bump" {}
        _BumpScale("Bump Scale",Float) = 1.0

        _Diffuse("Diffuse",color)   = ( 1.0 , 1.0 ,  1.0, 1.0)
        _Specular("Specular",color) = ( 1.0 , 1.0 , 1.0, 1.0)
        _GLOSS("gloss",Range(20.0,240)) = 20.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode" = "ForwardBase" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
    

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                fixed4 normal: NORMAL;
                fixed4 tangent: TANGENT;
                
                float2 uv : TEXCOORD0;

            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
        
                float4 vertex : SV_POSITION;

                //tangent to world matrix
                fixed4 T2W0 :TEXCOORD1;
                fixed4 T2W1 :TEXCOORD2;
                fixed4 T2W2 :TEXCOORD3;
            
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;


            sampler2D _BumpTex;
            float4 _BumpTex_ST;

            float _BumpScale;


            fixed4 _Diffuse;
            fixed4 _Specular;
            float _GLOSS;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv.xy , _BumpTex);//对Normal map做拆分

                //切线，副切线，法线
                //这里有个转化的问题
                // fixed4 tanBiNormal = cross(v.normal.xyz ,v.tangent.xyz) * v.tangent.w;

                //还是写错了。
                // fixed3 worldNormal  = WorldSpaceViewDir( v.normal  );
                // fixed3 worldTangent = WorldSpaceViewDir( v.tangent );


                //这个是世界方向 ,法线的切线变换 
                fixed3 worldNormal  = UnityObjectToWorldNormal( v.normal  );//normal 要专门计算
                fixed3 worldTangent = UnityObjectToWorldDir( v.tangent );


                fixed3 worldBiNormal = cross(worldNormal.xyz ,worldTangent.xyz) * v.tangent.w;

                fixed3 worldPos = mul((fixed3x3)unity_ObjectToWorld, o.vertex ).xyz;
                
                //分别算出三个轴，根据三个轴做转化 ,4.6.2 还是有一些迷糊
                //拿到在目标坐标系的x,y,z轴，然后按照列展开。  （即分别x轴展开，y轴展开和z轴展开）
                o.T2W0 = fixed4( worldTangent.x , worldBiNormal.x, worldNormal.x , worldPos.x);
                o.T2W1 = fixed4( worldTangent.y , worldBiNormal.y, worldNormal.y , worldPos.y);
                o.T2W2 = fixed4( worldTangent.z , worldBiNormal.z ,worldNormal.z , worldPos.z); 

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 abedo = tex2D(_MainTex, i.uv.xy);

                fixed4 packedNormal = tex2D(_BumpTex,i.uv.zw);
                fixed3 tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt( 1 - saturate( dot(tangentNormal.xy , tangentNormal.xy) ) );


                //矩阵乘法还可以用点乘算回去。
                // fixed3x3 tangentToWorldMatrix = fixed3x3( i.T2W0.xyz, i.T2W1.xyz, i.T2W2.xyz );
                fixed3 worldPos = fixed3(i.T2W0.z , i.T2W1.z , i.T2W2.z );

                fixed3 worldViewDir  = normalize( UnityWorldSpaceViewDir(worldPos)  );
                fixed3 worldLightDir = normalize( UnityWorldSpaceLightDir(worldPos) );
                fixed3 halfVector    = normalize( worldViewDir + worldLightDir );

                // //第二个问题， 是展开还是非展开，那个 _Bumpscale 的问题， 还是放在unpack之后
                // fixed3 worldNormal = mul( tangentToWorldMatrix ,tangentNormal );
                // worldNormal.xy *= _BumpScale;
                // worldNormal.z = sqrt( 1 - saturate (dot(worldNormal.xy , worldNormal.xy ) ) );


                //这里使用一个点乘，可以少构建一个matrix 转换矩阵 ,还要必须有个normalize
                fixed3 worldNormal = normalize( fixed3(dot(i.T2W0.xyz , tangentNormal.xyz) ,dot(i.T2W1.xyz , tangentNormal.xyz) ,dot(i.T2W2.xyz , tangentNormal.xyz)) );


                fixed3 ambient =  UNITY_LIGHTMODEL_AMBIENT.xyz * abedo.xyz;
                fixed3 diffuse =  _LightColor0.xyz * _Diffuse.xyz * abedo.xyz * saturate (dot( worldNormal ,worldLightDir ));

                fixed3 specular = _Specular.xyz * _LightColor0.xyz * pow( max(0 , dot( worldNormal , halfVector )) , _GLOSS );



              
                return fixed4( ambient + diffuse + specular   , 1.0);
            }
            ENDCG
        }
    }
}
