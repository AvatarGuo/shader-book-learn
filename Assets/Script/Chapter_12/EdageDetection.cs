using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class EdageDetection : PostEffectsBase
{
    public Shader edageDetectShader;
    private Material edageDetectMat;

    [SerializeField,Range(0.0f , 1.0f)]
    private float edgesOnly;

    [SerializeField] 
    private Color edgeColor = Color.black;

    [SerializeField]
    private Color backgroundColor = Color.black;

    public Material material
    {
        get
        {
            if (edageDetectMat == null)
            {
                edageDetectMat = CheckShaderAndCreateMaterial(edageDetectShader, edageDetectMat);
            }
            return edageDetectMat;
        }
    }

    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        //核心API graphic.blit( src, dst, material )
        if (material != null)
        {
            //核心api
            material.SetFloat("_EdgeOnly", edgesOnly);
            material.SetColor("_EdgeColor", edgeColor);
            material.SetColor("_BackgroundColor", backgroundColor);

            Graphics.Blit(src, dst, material);
        }
        else
        {
            Graphics.Blit(src,dst);
        }
    }
}
