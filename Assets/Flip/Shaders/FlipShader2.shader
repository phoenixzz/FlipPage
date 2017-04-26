Shader "Custom/FlipShader2"
{
	Properties
	{
		// upper page texture
		_SourceTex ("Upper Texture", 2D) = "white" {}
		// bottom page texture
		_TargetTex ("Bottom Texture", 2D) = "white" {}
		// 
		flip_time ("Range Time", Range(0.0, 0.99)) = 0
		// page curl radius
		radius ("Flip Radius", Range(0.05, 0.6)) = 0.1
	}
	SubShader
	{

		Tags { "RenderType"="Opaque" }
		LOD 200

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.uv;
				return o;
			}



			// Create by Eduardo Castineyra - casty/2015
			// Creative Commons Attribution 4.0 International License



			sampler2D _SourceTex;
			sampler2D _TargetTex;
						
			uniform float flip_time;			// Range from 0.0 to 1.0
			uniform float radius;

			float3 cyl;
			#define DIST 2

			// 1D function x : curlFun(t), y : normal at that point
			float2 curlFun(in float t, in float maxt)
			{
				float2 ret = float2(t, 1.0);
				
				// Before the curl
				if (t < (cyl[DIST] - radius))
					return ret;

				// After the curl
				if (t > (cyl[DIST] + radius))
					return float2(-1.0, -1.0);					

				// Inside the curl
				float a = asin((t - cyl[DIST]) / radius);
				float ca = UNITY_PI - a;				
				
				ret.x = cyl[DIST] + ca * radius;
				ret.y = cos(ca);				

				// We see the back face
				if (ret.x < maxt)
					return ret;

				// Front face before the curve starts
				if (t < cyl[DIST])
					return float2(t, 1.0);

				ret.y = cos(a);
				ret.x = cyl[DIST] + a * radius;

				// Front face curve
				return (ret.x < maxt) ? ret : float2(-1.0, -1.0);
			}


			float4 frag (v2f i) : SV_Target
			{
				float2 uv = i.uv;
				uv.y = 1.0 - uv.y;

				float2 ur = float2(1.0, 1.0);
				float2 mouse = float2(1.0 - flip_time, 0.1 * (1.0 - flip_time));
				float d = length(mouse * (1.0 + 4.0 * radius)) - 2.0 * radius;
				cyl = float3(normalize(mouse), d);
				d = dot(uv, cyl.xy);				

				float2 end = abs((ur - uv) / cyl.xy);				
				float maxt = d + min(end.x, end.y);				
				float2 cf = curlFun(d, maxt);				
				float2 tuv = uv + cyl.xy * (cf.x - d);

				float shadow = 1.0 - smoothstep(0.0, radius * 2.0, -(d - cyl[DIST]));
				shadow *= smoothstep(-radius, radius, (maxt - (cf.x + 1.5 * UNITY_PI * radius + radius)));

				tuv.y = 1.0 - tuv.y;
				float4 curr = tex2D(_SourceTex, tuv / ur);

				curr = cf.y > 0.0 ? curr * cf.y * (1.0 - shadow) : (curr * 0.25 + 0.75) * (-cf.y);
				shadow = smoothstep(0.0, radius * 2.0, (d - cyl[DIST]));

				uv.y = 1.0 - uv.y;
				float4 next = tex2D(_TargetTex, uv / ur) * shadow;
				
				return (cf.x > 0.0) ? curr : next;				
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
