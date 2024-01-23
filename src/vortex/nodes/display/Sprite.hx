package vortex.nodes.display;

import glad.Glad;

import vortex.backend.Application;

import vortex.servers.rendering.OpenGLBackend;

import vortex.resources.Shader;
import vortex.resources.Texture;

import vortex.utils.math.Vector2;
import vortex.utils.math.Vector3;
import vortex.utils.math.Vector4;
import vortex.utils.math.Rectangle;
import vortex.utils.math.Matrix4x4;

/**
 * A basic sprite class that can render a texture.
 */
class Sprite extends Node2D {
	/**
	 * The texture that this sprite draws.
	 */
	public var texture(default, set):Texture;

	/**
	 * The rendered portion of the texture.
	 * 
	 * Set to `null` to render the whole texture.
	 */
	public var clipRect(default, set):Rectangle;
	
	/**
	 * Called when this sprite is drawing internally.
	 * 
	 * Draw your own stuff in here if you need to,
	 * just make sure to call `super.draw()` before-hand!
	 */
	override function draw() {
		final shader:Shader = this.shader ?? OpenGLBackend.defaultShader;
		@:privateAccess {
			shader.useProgram();
			Glad.activeTexture(Glad.TEXTURE0);
			Glad.bindTexture(Glad.TEXTURE_2D, texture._glID);
			Glad.bindVertexArray(OpenGLBackend.curWindow._VAO);
		}
		prepareShaderVars(shader);
		Glad.drawElements(Glad.TRIANGLES, 6, Glad.UNSIGNED_INT, 0);
	}

	/**
	 * Disposes of this sprite and removes it's
	 * properties from memory.
	 */
	override function dispose() {
		if(!disposed) {
			if(texture != null)
				texture.unreference();
			
			_clipRectUVCoords = null;
		}
		super.dispose();
	}

	// -------- //
	// Privates //
	// -------- //
	private static var _trans = new Matrix4x4();
	private static var _vec2 = new Vector2();
	private static var _vec3 = new Vector3();
	
	private function prepareShaderVars(shader:Shader) {
		_trans.reset(1.0);
		
        _vec2.set((_clipRectUVCoords.z - _clipRectUVCoords.x) * texture.size.x * scale.x, (_clipRectUVCoords.w - _clipRectUVCoords.y) * texture.size.y * scale.y);
        _trans.scale(_vec3.set(_vec2.x, _vec2.y, 1.0));

        if (angle != 0.0) {
			_trans.translate(_vec3.set(-origin.x * _vec2.x, -origin.y * _vec2.y, 0.0));
            _trans.radRotate(angle, Vector3.AXIS_Z); 
			_trans.translate(_vec3.set(origin.x * _vec2.x, origin.y * _vec2.y, 0.0));
        }
		_trans.translate(_vec3.set(position.x + (-origin.x * _vec2.x), position.y + (-origin.y * _vec2.y), 0.0));
		
		shader.setUniformMat4x4("TRANSFORM", _trans);
		shader.setUniformColor("MODULATE", modulate);
		shader.setUniformVec4("SOURCE", _clipRectUVCoords);
	}
		
	// -------- //
	// Privates //
	// -------- //
	private var _clipRectUVCoords:Vector4 = new Vector4(0.0, 0.0, 1.0, 1.0);

	// ----------------- //
	// Getters & Setters //
	// ----------------- //
	@:noCompletion
	private inline function set_texture(newTexture:Texture):Texture {
		if(texture != null)
			texture.unreference();

		if(newTexture != null)
			newTexture.reference();

		texture = newTexture;

		if(clipRect != null)
			_updateClipRectUV(clipRect.x, clipRect.y, clipRect.width, clipRect.height);
		else
			_clipRectUVCoords.set(0.0, 0.0, 1.0, 1.0);

		return newTexture;
	}

	@:noCompletion
	private inline function set_clipRect(newRect:Rectangle):Rectangle {
		if(newRect != null) {
			@:privateAccess
			newRect._onChange = _updateClipRectUV;
			_updateClipRectUV(newRect.x, newRect.y, newRect.width, newRect.height);
		} else
			_clipRectUVCoords.set(0.0, 0.0, 1.0, 1.0);
		
		return clipRect = newRect;
	}

	@:noCompletion
	private inline function _updateClipRectUV(x:Float, y:Float, width:Float, height:Float) {
		_clipRectUVCoords.set(
			x / texture.size.x,
			y / texture.size.y,
			(x + width) / texture.size.x,
			(y + height) / texture.size.y
		);
	}
}