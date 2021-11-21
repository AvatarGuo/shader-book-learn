using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class MotionBlur : PostEffectsBase
{


    public Shader motionblurShader;

    [Range(0.0f ,0.9f )] 
    public float blurAmount = 0.5f;


    /// <summary>
    /// 贴图的累计缓存
    /// </summary>
    private RenderTexture accumulationTexture;




    private Material _material;

    public Material material
    {

        get
        {
            if ( _material == null)
            {
                _material = CheckShaderAndCreateMaterial( motionblurShader , _material );
            }
            return _material;

        }
    }

    
    void OnDisable()
    {
        if (accumulationTexture != null)
        {
            DestroyImmediate(accumulationTexture);
        }
    }


    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        
        if (material != null)
        {
            if (accumulationTexture == null || accumulationTexture.width != src.width || accumulationTexture.height != src.height)
            {

                if (accumulationTexture != null)
                {
                    DestroyImmediate(accumulationTexture);
                }
                
                accumulationTexture = new RenderTexture(src.width , src.height , 0);
                accumulationTexture.hideFlags = HideFlags.HideAndDontSave;
                
                Graphics.Blit(src,accumulationTexture);
            }


            //
            accumulationTexture.MarkRestoreExpected();

            //
            material.SetFloat("_BlurAmount", 1.0f - blurAmount);

            // 
            Graphics.Blit(src , accumulationTexture , material );
            Graphics.Blit(accumulationTexture , dst );

        }
        else
        {
            Graphics.Blit(src,dst);

        }

    }

}
