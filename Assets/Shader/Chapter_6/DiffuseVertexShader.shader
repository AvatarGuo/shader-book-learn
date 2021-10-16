Shader "Unity Shader book/Chapter6/Diffuse Vertex Shader"
{
    Properties
    {
        //color的范围是0-255，这里已经被归一化了，这样在进下计算就不会有之前那些问题了
        //比如之前问hjw的那个问题，比如srgb 需要pow(2.2),全部归一化到0-1，pow 极限等于1
        _Diffuse("Diffuse",color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" }

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            // make fog work

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

           struct a2v
           {
                float4 vertex: POSITION;
                fixed4 normal: NORMAL; //存储的是模型空间 还是顶点空间？ 这个问题。
           };

            struct v2f
            {
                float4 pos : SV_POSITION ;
                fixed3 color : COLOR0 ; //语义 https://docs.unity3d.com/Manual/SL-VertexProgramInputs.html
            };

            fixed4 _Diffuse;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex); 
                
                //
                //ambient(环境光) + diffuse（漫反射） + specular（高光）
                fixed3 ambient =  UNITY_LIGHTMODEL_AMBIENT.xyz; //(color bleed))
                
                //法线变换矩阵，利用tangent（切线空间）的空间约束条件做个限制，http://candycat1992.github.io/unity_shaders_book/unity_shaders_book_chapter_4.pdf 55-p93

                fixed3 worldNormal = normalize(mul(v.normal , (float3x3)unity_WorldToObject ));
                fixed3 worldLight  = normalize(_WorldSpaceLightPos0.xyz);

                //Cdiffuse = Cliht*Cdiffuse*max(n,l)
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.xyz * saturate(dot(worldNormal,worldLight));
                o.color = ambient + diffuse;

                return o;
            };

            //计算表面diffuse的部分，进入皮肤上加个偏移即可了。
            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(i.color.xyz,1);
            };
            ENDCG
        }

    }

    //紧跟着某个subshader后面做保底，而不是在subshader里面。
    Fallback "Diffuse"

}
