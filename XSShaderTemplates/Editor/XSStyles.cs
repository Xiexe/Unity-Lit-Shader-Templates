using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using System.IO;
namespace XSTemplateShaders
{
    [InitializeOnLoad]
    public class XSStyles : MonoBehaviour
    {
        // Labels
        public static void DoHeader(GUIContent HeaderText)
        {
            GUILayout.Label(HeaderText, new GUIStyle(EditorStyles.boldLabel)
            {
                alignment = TextAnchor.MiddleCenter,
                wordWrap = true,
                fontSize = 12
            });
        }

        public static void DoHeaderLeft(string text)
        {
            GUILayout.Label(text, new GUIStyle(EditorStyles.boldLabel)
            {
                alignment = TextAnchor.MiddleLeft,
                wordWrap = true,
                fontSize = 12
            });
        }

        public static void doLabel(string text)
        {
            GUILayout.Label(text, new GUIStyle(EditorStyles.label)
            {
                alignment = TextAnchor.MiddleCenter,
                wordWrap = true,
                fontSize = 12
            });
        }

        public static void doLabelLeft(string text)
        {
            GUILayout.Label(text, new GUIStyle(EditorStyles.label)
            {
                alignment = TextAnchor.MiddleLeft,
                wordWrap = true,
                fontSize = 12
            });
        }

        public static void doLabelSmall(string text)
        {
            GUILayout.Label(text, new GUIStyle(EditorStyles.label)
            {
                alignment = TextAnchor.MiddleLeft,
                wordWrap = true,
                fontSize = 10
            });
        }
        // ----

        static public GUIStyle _LineStyle;
        static public GUIStyle LineStyle
        {
            get
            {
                if (_LineStyle == null)
                {
                    _LineStyle = new GUIStyle();
                    _LineStyle.normal.background = EditorGUIUtility.whiteTexture;
                    _LineStyle.stretchWidth = true;
                }

                return _LineStyle;
            }
        }

        //GUI Buttons

        //------

        //Help Box
        public static void HelpBox(string message, MessageType type)
        {
            EditorGUILayout.HelpBox(message, type);
        }

        //GUI Lines
        static public void Separator()
        {
            GUILayout.Space(10);
            GUILine(new Color(.1f, .1f, .1f), 1f);
            GUILine(new Color(.3f, .3f, .3f), 2f);
            GUILayout.Space(10);
        }

        static public void SeparatorThin()
        {
            GUILayout.Space(6);
            GUILine(new Color(.1f, .1f, .1f), 1f);
            GUILine(new Color(.3f, .3f, .3f), 1f);
            GUILayout.Space(6);
        }

        static public void SeparatorBig()
        {
            GUILayout.Space(10);
            GUILine(new Color(.3f, .3f, .3f), 2);
            GUILayout.Space(1);
            GUILine(new Color(.3f, .3f, .3f), 2);
            GUILine(new Color(.85f, .85f, .85f), 1);
            GUILayout.Space(10);
        }

        static public void GUILine(float height = 2f)
        {
            GUILine(Color.black, height);
        }

        static public void GUILine(Color color, float height = 2f)
        {
            Rect position = GUILayoutUtility.GetRect(0f, float.MaxValue, height, height, LineStyle);

            if (Event.current.type == EventType.Repaint)
            {
                Color orgColor = GUI.color;
                GUI.color = orgColor * color;
                LineStyle.Draw(position, false, false, false, false);
                GUI.color = orgColor;
            }
        }
        // --------------

        private static Rect DrawShuriken(string title, Vector2 contentOffset, int HeaderHeight)
        {
            var style = new GUIStyle("ShurikenModuleTitle");
            style.font = new GUIStyle(EditorStyles.boldLabel).font;
            style.border = new RectOffset(15, 7, 4, 4);
            style.fixedHeight = HeaderHeight;
            style.contentOffset = contentOffset;
            var rect = GUILayoutUtility.GetRect(16f, HeaderHeight, style);

            GUI.Box(rect, title, style);
            return rect;
        }

        private static Rect DrawShurikenCenteredTitle(string title, Vector2 contentOffset, int HeaderHeight)
        {
            var style = new GUIStyle("ShurikenModuleTitle");
            style.font = new GUIStyle(EditorStyles.boldLabel).font;
            style.border = new RectOffset(15, 7, 4, 4);
            style.fixedHeight = HeaderHeight;
            style.contentOffset = contentOffset;
            style.alignment = TextAnchor.MiddleCenter;
            var rect = GUILayoutUtility.GetRect(16f, HeaderHeight, style);

            GUI.Box(rect, title, style);
            return rect;
        }

        public static bool ShurikenFoldout(string title, bool display)
        {
            var rect = DrawShuriken(title, new Vector2(20f, -2f), 22);
            var e = Event.current;
            var toggleRect = new Rect(rect.x + 4f, rect.y + 2f, 13f, 13f);
            if (e.type == EventType.Repaint)
            {
                EditorStyles.foldout.Draw(toggleRect, false, false, display, false);
            }
            if (e.type == EventType.MouseDown && rect.Contains(e.mousePosition))
            {
                display = !display;
                e.Use();
            }
            return display;
        }

        public static void ShurikenHeader(string title)
        {
            DrawShuriken(title, new Vector2(6f, -2f), 22);
        }

        public static void ShurikenHeaderCentered(string title)
        {
            DrawShurikenCenteredTitle(title, new Vector2(0f, -2f), 22);
        }

        public static void ConstrainedShaderProperty(MaterialEditor materialEditor, MaterialProperty prop, GUIContent style, int tabSize)
        {
            EditorGUILayout.BeginHorizontal(GUILayout.MaxWidth(30));
                materialEditor.ShaderProperty(prop, style, tabSize);
            EditorGUILayout.EndHorizontal();
        }

        public static bool HelpBoxWithButton(GUIContent messageContent, GUIContent buttonContent)
        {
            const float kButtonWidth = 60f;
            const float kSpacing = 5f;
            const float kButtonHeight = 20f;

            // Reserve size of wrapped text
            Rect contentRect = GUILayoutUtility.GetRect(messageContent, EditorStyles.helpBox);
            // Reserve size of button
            GUILayoutUtility.GetRect(1, kButtonHeight + kSpacing);

            // Render background box with text at full height
            contentRect.height += kButtonHeight + kSpacing;
            GUI.Label(contentRect, messageContent, EditorStyles.helpBox);

            // Button (align lower right)
            Rect buttonRect = new Rect(contentRect.xMax - kButtonWidth - 4f, contentRect.yMax - kButtonHeight - 4f, kButtonWidth, kButtonHeight);
            return GUI.Button(buttonRect, buttonContent);
        }
    }
}
