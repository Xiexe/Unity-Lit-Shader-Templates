using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;
using System.Reflection;

namespace XSTemplateShaders
{
    public partial class FoldoutToggles
    {
        public bool ShowMain = true;
        public bool ShowSubsurface = false;
        public bool ShowEmission = false;
        public bool ShowAdvanced = false;
        public bool ShowEyeTracking = false;
        public bool ShowAudioLink = false;
        public bool ShowDissolve = false;
        public bool ShowFur = false;
    }

    public class TemplateShaderBaseInspector : ShaderGUI
    {
        protected static Dictionary<Material, FoldoutToggles> Foldouts = new Dictionary<Material, FoldoutToggles>();
        protected BindingFlags bindingFlags = BindingFlags.Public |
                                    BindingFlags.NonPublic |
                                    BindingFlags.Instance |
                                    BindingFlags.Static;

        //Assign all properties as null at first to stop hundreds of warnings spamming the log when script gets compiled.
        //If they aren't we get warnings, because assigning with reflection seems to make Unity think that the properties never actually get used.

        protected MaterialProperty _BlendMode = null;
        protected MaterialProperty _LightProbeMethod = null;
        protected MaterialProperty _TextureSampleMode = null;
        protected MaterialProperty _TriplanarFalloff = null;
        protected MaterialProperty _MainTex = null;
        protected MaterialProperty _Color = null;
        protected MaterialProperty _Cutoff = null;
        protected MaterialProperty _BumpMap = null;
        protected MaterialProperty _BumpScale = null;
        protected MaterialProperty _MetallicGlossMap = null;
        protected MaterialProperty _Metallic = null;
        protected MaterialProperty _Glossiness = null;
        protected MaterialProperty _Reflectance = null;
        protected MaterialProperty _Anisotropy = null;
        protected MaterialProperty _OcclusionMap = null;
        protected MaterialProperty _OcclusionColor = null;
        protected MaterialProperty _SubsurfaceMethod = null;
        protected MaterialProperty _CurvatureThicknessMap = null;
        protected MaterialProperty _SubsurfaceColorMap = null;
        protected MaterialProperty _SubsurfaceScatteringColor = null;
        protected MaterialProperty _SubsurfaceInheritDiffuse = null;
        protected MaterialProperty _TransmissionNormalDistortion = null;
        protected MaterialProperty _TransmissionPower = null;
        protected MaterialProperty _TransmissionScale = null;
        protected MaterialProperty _EmissionMap = null;
        protected MaterialProperty _EmissionColor = null;
        protected MaterialProperty _ClearcoatMap = null;
        protected MaterialProperty _Clearcoat = null;
        protected MaterialProperty _ClearcoatGlossiness = null;
        protected MaterialProperty _ClearcoatAnisotropy = null;
        protected MaterialProperty _VertexOffset = null;
        protected MaterialProperty _TessellationMode = null;
        protected MaterialProperty _TessellationUniform = null;
        protected MaterialProperty _TessClose = null;
        protected MaterialProperty _TessFar = null;
        protected MaterialProperty _SpecularLMOcclusion = null;
        protected MaterialProperty _SpecLMOcclusionAdjust = null;
        protected MaterialProperty _LMStrength = null;
        protected MaterialProperty _RTLMStrength = null;
        //

        private static bool OverrideRenderSettings = false;
        protected static int BlendMode;
        protected static bool IsCutout;
        protected static bool IsDithered;
        protected static bool IsA2C;

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            Material material = materialEditor.target as Material;
            Shader shader = material.shader;

            BlendMode = material.GetInt("_BlendMode");
            IsCutout = BlendMode == 1;
            IsDithered = BlendMode == 2;
            IsA2C = BlendMode == 3;

            SetupFoldoutDictionary(material);

            //Find all material properties listed in the script using reflection, and set them using a loop only if they're of type MaterialProperty.
            //This makes things a lot nicer to maintain and cleaner to look at.
            foreach (var property in GetType().GetFields(bindingFlags))
            {
                if (property.FieldType == typeof(MaterialProperty))
                {
                    try { property.SetValue(this, FindProperty(property.Name, props)); } catch { /*Is it really a problem if it doesn't exist?*/ }
                }
            }

            EditorGUI.BeginChangeCheck();

            DoBlendModeSettings(material);
            DrawMainSettings(materialEditor, material);
            DrawEmissionSettings(materialEditor, material);
            DrawTransmissionSettings(materialEditor, material);
            DrawLightmappingSettings(materialEditor, material);
            PluginGUI(materialEditor, material);
        }

        public virtual void PluginGUI(MaterialEditor materialEditor, Material material) {
        }

        private void SetupFoldoutDictionary(Material material)
        {
            if (Foldouts.ContainsKey(material))
                return;

            FoldoutToggles toggles = new FoldoutToggles();
            Foldouts.Add(material, toggles);
        }

        private void DoBlendModeSettings(Material material)
        {
            if (OverrideRenderSettings)
                return;

            switch (BlendMode)
            {
                case 0: //Opaque
                    SetBlend(material, (int) UnityEngine.Rendering.BlendMode.One,
                        (int) UnityEngine.Rendering.BlendMode.Zero,
                        (int) UnityEngine.Rendering.RenderQueue.Geometry, 1, 0);
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHATEST_ON");
                    break;

                case 1: //Cutout
                    SetBlend(material, (int) UnityEngine.Rendering.BlendMode.One,
                        (int) UnityEngine.Rendering.BlendMode.Zero,
                        (int) UnityEngine.Rendering.RenderQueue.AlphaTest, 1, 0);
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.EnableKeyword("_ALPHATEST_ON");
                    break;

                case 2: //Dithered
                    SetBlend(material, (int) UnityEngine.Rendering.BlendMode.One,
                        (int) UnityEngine.Rendering.BlendMode.Zero,
                        (int) UnityEngine.Rendering.RenderQueue.AlphaTest, 1, 0);
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.EnableKeyword("_ALPHATEST_ON");
                    break;

                case 3: //Alpha To Coverage
                    SetBlend(material, (int) UnityEngine.Rendering.BlendMode.One,
                        (int) UnityEngine.Rendering.BlendMode.Zero,
                        (int) UnityEngine.Rendering.RenderQueue.AlphaTest, 1, 1);
                    material.EnableKeyword("_ALPHABLEND_ON");
                    material.EnableKeyword("_ALPHATEST_ON");
                    break;

                case 4: //Transparent
                    SetBlend(material, (int) UnityEngine.Rendering.BlendMode.One,
                        (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha,
                        (int) UnityEngine.Rendering.RenderQueue.Transparent, 0, 0);
                    material.EnableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHATEST_ON");
                    break;

                case 5: //Fade
                    SetBlend(material, (int) UnityEngine.Rendering.BlendMode.SrcAlpha,
                        (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha,
                        (int) UnityEngine.Rendering.RenderQueue.Transparent, 0, 0);
                    material.EnableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHATEST_ON");
                    break;

                case 6: //Additive
                    SetBlend(material, (int) UnityEngine.Rendering.BlendMode.One,
                        (int) UnityEngine.Rendering.BlendMode.One,
                        (int) UnityEngine.Rendering.RenderQueue.Transparent, 0, 0);
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHATEST_ON");
                    break;
            }
        }

        private void SetBlend(Material material, int src, int dst, int renderQueue, int zwrite, int alphatocoverage)
        {
            material.SetInt("_SrcBlend", src);
            material.SetInt("_DstBlend", dst);
            material.SetInt("_ZWrite", zwrite);
            material.SetInt("_AlphaToMask", alphatocoverage);
            material.renderQueue = renderQueue;
        }

        private void DrawMainSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowMain = XSStyles.ShurikenFoldout("Main Settings", Foldouts[material].ShowMain);
            if (Foldouts[material].ShowMain)
            {
                materialEditor.TexturePropertySingleLine(new GUIContent("Main Texture", "The main Albedo texture."), _MainTex, _Color);
                if (IsCutout)
                {
                    materialEditor.ShaderProperty(_Cutoff, new GUIContent("Cutoff", "The Cutoff Amount"), 2);
                }
                materialEditor.TextureScaleOffsetProperty(_MainTex);
            }
        }

        private void DrawEmissionSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowEmission = XSStyles.ShurikenFoldout("Emission", Foldouts[material].ShowEmission);
            if (Foldouts[material].ShowEmission)
            {
            }
        }

        private void DrawTransmissionSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowSubsurface = XSStyles.ShurikenFoldout("Transmission", Foldouts[material].ShowSubsurface);
            if (Foldouts[material].ShowSubsurface)
            {
            }
        }

        private void DrawLightmappingSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowAdvanced = XSStyles.ShurikenFoldout("Lightmapping Settings", Foldouts[material].ShowAdvanced);
            if (Foldouts[material].ShowAdvanced)
            {
            }
        }

        private Vector4 ClampVec4(Vector4 vec)
        {
            Vector4 value = vec;
            value.x = Mathf.Clamp01(value.x);
            value.y = Mathf.Clamp01(value.y);
            value.z = Mathf.Clamp01(value.z);
            value.w = Mathf.Clamp01(value.w);
            return value;
        }
    }
}
