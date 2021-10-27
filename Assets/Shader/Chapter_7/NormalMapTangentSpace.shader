// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


//要注意的是：  1. 贴图要勾选normal map ,才能用unity 的build-in method的 unpackNormal方法：2019实测，不需要勾选该选项也可以。
//             2. 均匀缩放和非均匀缩放，转世界空间 在转tangent空间可以支持任意缩放。
//             3. 4.6.2 关于任意空间变换的问题。 
Shader "Unity Shader book/Chapter7/NormalMapTangetSpace"
{

    Properties{

        _Diffuse("diffuse",color)   = ( 1.0, 1.0 ,1.0 ,1.0)

        _Specular("specular",color) = ( 1.0, 1.0 ,1.0 ,1.0)
        _Gloss("gloss",Range(20,240)) = 20

        _MainTex("main texture",2D) = "white" {}
        _BumpMap("normal map",2D)   = "bump"  {} // 这里的bump 贴图是Unity 内部默认的第一个normal map 设置的。
        _BumpScale("bump scale",Float) = 1.0

    }


    SubShader{


        Tags{
                "RenderType" = "Opaque" 
                "LightMode"  = "ForwardBase"
            }

        Pass {

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            sampler2D _MainTex;
            fixed4 _MainTex_ST;


            sampler2D _BumpMap;
            fixed4 _BumpMap_ST;

            fixed4 _Diffuse;
            fixed4 _Specular;

            float _BumpScale;
            float _Gloss;

            struct appdata{
                fixed4 position:POSITION;

                // //这里的Normal 到底是模型的 还是贴图的呢？
                fixed4 normal:NORMAL;
                fixed4 tangent:TANGENT;
                fixed4 texcoord:TEXCOORD0;  //第一组纹理贴图
            };


            struct v2f {

                fixed4 position:SV_POSITION;

                float4 uv:TEXCOORD0;

                fixed3 lightDir:TEXCOORD1;
                fixed3 viewDir:TEXCOORD2;
                // fixed3 normal:TEXCOORD3; 这里不用顶点自身的normal信息了，因为加了一个法线贴图，所以unpack法线贴图的值，获取的即是切线空间的法线值了,法线空间求值的一些方法。 
            };


            v2f vert(appdata v){
                v2f o;
                o.position = UnityObjectToClipPos(v.position);

                //准备采样贴图
                //注意：这里都用了第一个texcoord 去计算uv的为什么？？？？
                o.uv.xy = v.texcoord.xy *  _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy *  _BumpMap_ST.xy + _BumpMap_ST.zw;

                //模型空间的计算
                //注意：不在vs中进行归一化，因为会平均,有x的值，有y的值，有z的值。
                //！！ v.tangent.w 存储的是法线的方向，
                fixed3 binormal   = cross( normalize( v.normal.xyz ) , normalize( v.tangent.xyz )  ) * v.tangent.w;  
                fixed3x3 rotation = fixed3x3( v.tangent.xyz , binormal.xyz , v.normal.xyz ); //shader 入门精要 4.6.2 的坐标轴空间变换。


                o.lightDir = mul(rotation , ObjSpaceLightDir(v.position).xyz);
                o.viewDir  = mul(rotation , ObjSpaceViewDir(v.position).xyz); //view dir做个划分
                // o.normal   = mul(rotation,normal);//这里不需要在计算normal了，因为之后要计算了
                return o;
            };


            fixed4 frag(v2f i) : SV_Target {

                // ambient +  diffuse +  specular
                // 先采样abedo 贴图
                fixed3 abedo  = tex2D( _MainTex , i.uv.xy ) * _Diffuse.xyz;

                //opengl 和 direct X 
                //采样计算xy,zw 
                fixed4 tanPackNormal = tex2D( _BumpMap , i.uv.zw) ; //切线空间的 pack normal ,有个压缩映射，需要放大回来。 [0,1]->[-1,1] ,但是只有xy空间的需要这样做。
                fixed3 tanNormal ;
                // tanNormal.xy = (tanPackNormal.xy * 2 - 1) * _BumpScale ;
                // tanNormal.z = sqrt(1.0 - saturate(dot(tanNormal.xy, tanNormal.xy ))  );

                tanNormal = UnpackNormal(tanPackNormal);
				tanNormal.xy *= _BumpScale;
				tanNormal.z = sqrt(1.0 - saturate(dot(tanNormal.xy, tanNormal.xy)));



                fixed3 lightDir = normalize( i.lightDir );
                fixed3 viewDir = normalize(i.viewDir);
                fixed3 lightColor = _LightColor0.xyz;           //

                // //环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * abedo; //环境光 * abedo 采样
                // //漫反射
                fixed3 diffuse = lightColor * _Diffuse.xyz * abedo.xyz * max(0.1,dot( lightDir,tanNormal )); //这里要和normal 计算，但是normal 是在切线空间的，要从切线空间变成世界空间？ 


                //
                fixed3 halfVector = normalize( viewDir + lightDir );
                fixed3 specular = lightColor * _Specular.xyz * pow( max( 0, dot( tanNormal , halfVector )) , _Gloss ) ;


                fixed3 color = ambient + diffuse + specular ;
                return fixed4( color.xyz ,1.0);

            };

            ENDCG

        }

    }






}
