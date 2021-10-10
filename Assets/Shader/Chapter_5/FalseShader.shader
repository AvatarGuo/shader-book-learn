// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shader book/Chapter5/False Shader"
{
    SubShader{

        Pass{
            
            CGPROGRAM

            
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            
            struct v2f{
                float4 position:SV_POSITION;
                fixed4 color:COLOR0;
            };


            //appdata_full中的值现在都是模型空间的值
            v2f vert(appdata_full v){

                
                v2f i;
                
                //这个时候还在线性空间中 
                i.position = UnityObjectToClipPos(v.vertex);
                //除以w 分量才能到ndc空间中[-1,1]，然后在ndc中间 *0.5 + 0.5 => 变换到屏幕空间中）
                //一般不在vs中进行ndc变换，(只做mvp变换，在写引擎的时候需要考虑这个问题)
                //1 .因为z轴变换后是非线性的了。
                //2 .vs算出来的值 会平均给到vs，一个非线性的平均会出问题
                //入门精要p92页
                
                //normal
                i.color = fixed4(v.normal * 0.5 + fixed3(0.5,0.5,0.5), 1. );
                
                //tangent
                i.color = fixed4(v.tangent.rgb*0.5 + fixed3(.5,.5,.5) , 1. );

                //副切线 公式要求下，42有个优化去掉了副切线
                //这里的tangent 是切线（是顶点的属性，因此可以用和顶点相同的属性去做变换，法线则不可以。

                //求副切线
                fixed3 binormal = cross( v.normal , v.tangent.xyz ) * v.tangent.w;
                i.color = fixed4(binormal*0.5 + fixed3(0.5,.5,.5), 1.);


                //可视化第一组纹理坐标
                i.color = fixed4(v.texcoord.xy, 0., 1.);

                //可视化第二组纹理坐标、
                i.color = fixed4(v.texcoord1.xy,0. , 1.);

                //可视化第一组纹理坐标的小数部分
                i.color = frac(v.texcoord);
                if(any(saturate( v.texcoord ) -v.texcoord   )){
                    i.color.b = 0.5;
                }
                i.color.a = 1.;


                //可视化第二组纹理坐标的小数部分
                i.color = frac(v.texcoord1);
                if(any(saturate(v.texcoord1)  - v.texcoord1)){
                    i.color.b = 0.5;
                }
                i.color.a = 1.;

                //可视化顶点颜色
                // i.color = v.color;

                return i;
            };


            fixed4 frag(v2f i):SV_Target {
               return i.color;

            };

            ENDCG
        }



    }



}

