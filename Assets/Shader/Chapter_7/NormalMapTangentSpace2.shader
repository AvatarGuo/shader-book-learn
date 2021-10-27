//冯乐乐有个方法是转化到世界空间在转化回局部空间的方法。

Shader "Unity Shader book/Chapter7/NormalMapTangetSpace 2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Diffuse("Diffuse",color) = (1.0 , 1.0 , 1.0 , 1.0)

        _Specular("Specular",color) = ( 1.0 , 1.0, 1.0, 1.0)
        _Gloss("Gloss",Range(20.0, 240 )) = 20

        _BumpTex("Normal Map",2D) = "Bump" {}
        _BumpScale("Bump Scale",Float) = 1.0
    }
    SubShader
    {
        Tags {
                "RenderType"="Opaque" 
                "LightMode" = "ForwardBase"
            }

        Pass
        {
            CGPROGRAM


            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"    //
            #include "UnityLightingCommon.cginc"    //lighting commmon

            struct appdata
            {

                float4 vertex : POSITION;

                float4 normal:NORMAL;       //都是在模型空间的值
                float4 tangent:TANGENT;

                float2 uv:TEXCOORD; //第一个采样贴图
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;

                float3 tangentViewDir:TEXCOORD1;
                float3 tangentLightDir:TEXCOORD2;

            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            //normal map
            sampler2D _BumpTex;
            float4 _BumpTex_ST;
            float _BumpScale;

            //
            float4  _Diffuse;
            float4  _Specular;
            float   _Gloss;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex); //获取顶点的位置
                o.uv.xy = TRANSFORM_TEX(v.uv , _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv , _BumpTex);
                //切线，副切线，法线
                fixed3 biNormal = cross( v.normal.xyz , v.tangent.xyz ) * v.tangent.w;

                //构建模型空间到法线空间的矩阵

                //  model to tangent  转化
                //  4.6.2章节，介绍的比较清楚，即世界转本地，本地转世界相关的，由x,y 反推z值
                fixed3x3 modeltoTanget = fixed3x3( v.tangent.xyz , biNormal.xyz, v.normal.xyz  );
                //tangent to  normal 

                //矩阵不用传了，直接表示就好了
                o.tangentViewDir  = mul( modeltoTanget , ObjSpaceViewDir(v.vertex) );
                o.tangentLightDir = mul( modeltoTanget , ObjSpaceLightDir(v.vertex) );

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                fixed4 abedo = tex2D(  _MainTex , i.uv.xy );

                //范围是-1,1范围内，可
                fixed4 packedNormal =  tex2D( _BumpTex , i.uv.zw );
                fixed3 tangentNormal = UnpackNormal(packedNormal); // *2 - 1 然后缩放回[-1,1] 范围内
                tangentNormal.xy *= _BumpScale;
                
                //本质就是normalize的方法又写了一遍
                tangentNormal.z = sqrt( 1 - saturate( dot( tangentNormal.xy ,tangentNormal.xy )) );



                fixed3 tangentLightDir = normalize( i.tangentLightDir.xyz );
                fixed3 tangentViewDir  = normalize( i.tangentViewDir.xyz );
                fixed3 halfVector = normalize( tangentLightDir  + tangentViewDir );


                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * abedo.xyz;
                
                fixed3 lightColor   =   _LightColor0.xyz;
                //diffuse 有两种模型，一种是lambert 一种是value 公司的那个*0.5 + 0.5的那个高亮模型
                fixed3 diffuse      =   _Diffuse.xyz  * lightColor *  abedo.xyz * max( 0 ,dot(tangentLightDir, tangentNormal ));


                //高光有两种模型，一种是half-lambert模型，一种是lambert 模型 ，简称Half-lambert
                fixed3 specular     =  _Specular.xyz * lightColor * pow( max( 0 , dot(halfVector, tangentNormal) )  ,   _Gloss);

                return fixed4(ambient + diffuse + specular , 1.0 );

            }
            ENDCG
        }
    }
}
