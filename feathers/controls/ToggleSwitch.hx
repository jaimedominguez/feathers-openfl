/*
Feathers
Copyright 2012-2014 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls;
import feathers.core.FeathersControl;
import feathers.core.IFocusDisplayObject;
import feathers.core.ITextRenderer;
import feathers.core.IToggle;
import feathers.core.PropertyProxy;
import feathers.skins.IStyleProvider;
import feathers.system.DeviceCapabilities;

import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.ui.Keyboard;

import starling.animation.Transitions;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.events.Event;
import starling.events.KeyboardEvent;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.utils.SystemUtil;

/**
 * @copy feathers.core.IToggle#event:change
 *///[Event(name="change",type="starling.events.Event")]

/**
 * Similar to a light switch with on and off states. Generally considered an
 * alternative to a check box.
 *
 * <p>The following example programmatically selects a toggle switch and
 * listens for when the selection changes:</p>
 *
 * <listing version="3.0">
 * var toggle:ToggleSwitch = new ToggleSwitch();
 * toggle.isSelected = true;
 * toggle.addEventListener( Event.CHANGE, toggle_changeHandler );
 * this.addChild( toggle );</listing>
 *
 * @see http://wiki.starling-framework.org/feathers/toggle-switch
 * @see Check
 */
class ToggleSwitch extends FeathersControl implements IToggle, IFocusDisplayObject
{
	/**
	 * @private
	 */
	private static var HELPER_POINT:Point = new Point();

	/**
	 * @private
	 * The minimum physical distance (in inches) that a touch must move
	 * before the scroller starts scrolling.
	 */
	inline private static var MINIMUM_DRAG_DISTANCE:Float = 0.04;

	/**
	 * @private
	 */
	inline private static var INVALIDATION_FLAG_THUMB_FACTORY:String = "thumbFactory";

	/**
	 * @private
	 */
	inline private static var INVALIDATION_FLAG_ON_TRACK_FACTORY:String = "onTrackFactory";

	/**
	 * @private
	 */
	inline private static var INVALIDATION_FLAG_OFF_TRACK_FACTORY:String = "offTrackFactory";

	/**
	 * The ON and OFF labels will be aligned to the middle vertically,
	 * based on the full character height of the font.
	 *
	 * @see #labelAlign
	 */
	inline public static var LABEL_ALIGN_MIDDLE:String = "middle";

	/**
	 * The ON and OFF labels will be aligned to the middle vertically,
	 * based on only the baseline value of the font.
	 *
	 * @see #labelAlign
	 */
	inline public static var LABEL_ALIGN_BASELINE:String = "baseline";

	/**
	 * The toggle switch has only one track skin, stretching to fill the
	 * full length of switch. In this layout mode, the on track is
	 * displayed and fills the entire length of the toggle switch. The off
	 * track will not exist.
	 *
	 * @see #trackLayoutMode
	 */
	inline public static var TRACK_LAYOUT_MODE_SINGLE:String = "single";

	/**
	 * The toggle switch has two tracks, stretching to fill each side of the
	 * scroll bar with the thumb in the middle. The tracks will be resized
	 * as the thumb moves. This layout mode is designed for toggle switches
	 * where the two sides of the track may be colored differently to better
	 * differentiate between the on state and the off state.
	 *
	 * <p>Since the width and height of the tracks will change, consider
	 * using a special display object such as a <code>Scale9Image</code>,
	 * <code>Scale3Image</code> or a <code>TiledImage</code> that is
	 * designed to be resized dynamically.</p>
	 *
	 * @see #trackLayoutMode
	 * @see feathers.display.Scale9Image
	 * @see feathers.display.Scale3Image
	 * @see feathers.display.TiledImage
	 */
	inline public static var TRACK_LAYOUT_MODE_ON_OFF:String = "onOff";

	/**
	 * The default value added to the <code>styleNameList</code> of the off label.
	 *
	 * @see feathers.core.FeathersControl#styleNameList
	 */
	inline public static var DEFAULT_CHILD_NAME_OFF_LABEL:String = "feathers-toggle-switch-off-label";

	/**
	 * The default value added to the <code>styleNameList</code> of the on label.
	 *
	 * @see feathers.core.FeathersControl#styleNameList
	 */
	inline public static var DEFAULT_CHILD_NAME_ON_LABEL:String = "feathers-toggle-switch-on-label";

	/**
	 * The default value added to the <code>styleNameList</code> of the off track.
	 *
	 * @see feathers.core.FeathersControl#styleNameList
	 */
	inline public static var DEFAULT_CHILD_NAME_OFF_TRACK:String = "feathers-toggle-switch-off-track";

	/**
	 * The default value added to the <code>styleNameList</code> of the on track.
	 *
	 * @see feathers.core.FeathersControl#styleNameList
	 */
	inline public static var DEFAULT_CHILD_NAME_ON_TRACK:String = "feathers-toggle-switch-on-track";

	/**
	 * The default value added to the <code>styleNameList</code> of the thumb.
	 *
	 * @see feathers.core.FeathersControl#styleNameList
	 */
	inline public static var DEFAULT_CHILD_NAME_THUMB:String = "feathers-toggle-switch-thumb";

	/**
	 * The default <code>IStyleProvider</code> for all <code>ToggleSwitch</code>
	 * components.
	 *
	 * @default null
	 * @see feathers.core.FeathersControl#styleProvider
	 */
	public static var globalStyleProvider:IStyleProvider;

	/**
	 * @private
	 */
	private static function defaultThumbFactory():Button
	{
		return new Button();
	}

	/**
	 * @private
	 */
	private static function defaultOnTrackFactory():Button
	{
		return new Button();
	}

	/**
	 * @private
	 */
	private static function defaultOffTrackFactory():Button
	{
		return new Button();
	}

	/**
	 * Constructor.
	 */
	public function ToggleSwitch()
	{
		super();
		this.addEventListener(TouchEvent.TOUCH, toggleSwitch_touchHandler);
		this.addEventListener(Event.REMOVED_FROM_STAGE, toggleSwitch_removedFromStageHandler);
	}

	/**
	 * The value added to the <code>styleNameList</code> of the off label. This
	 * variable is <code>private</code> so that sub-classes can customize
	 * the on label name in their constructors instead of using the default
	 * name defined by <code>DEFAULT_CHILD_NAME_ON_LABEL</code>.
	 *
	 * @see feathers.core.FeathersControl#styleNameList
	 */
	private var onLabelName:String = DEFAULT_CHILD_NAME_ON_LABEL;

	/**
	 * The value added to the <code>styleNameList</code> of the on label. This
	 * variable is <code>private</code> so that sub-classes can customize
	 * the off label name in their constructors instead of using the default
	 * name defined by <code>DEFAULT_CHILD_NAME_OFF_LABEL</code>.
	 *
	 * @see feathers.core.FeathersControl#styleNameList
	 */
	private var offLabelName:String = DEFAULT_CHILD_NAME_OFF_LABEL;

	/**
	 * The value added to the <code>styleNameList</code> of the on track. This
	 * variable is <code>private</code> so that sub-classes can customize
	 * the on track name in their constructors instead of using the default
	 * name defined by <code>DEFAULT_CHILD_NAME_ON_TRACK</code>.
	 *
	 * <p>To customize the on track name without subclassing, see
	 * <code>customOnTrackName</code>.</p>
	 *
	 * @see #customOnTrackName
	 * @see feathers.core.FeathersControl#styleNameList
	 */
	private var onTrackName:String = DEFAULT_CHILD_NAME_ON_TRACK;

	/**
	 * The value added to the <code>styleNameList</code> of the off track. This
	 * variable is <code>private</code> so that sub-classes can customize
	 * the off track name in their constructors instead of using the default
	 * name defined by <code>DEFAULT_CHILD_NAME_OFF_TRACK</code>.
	 *
	 * <p>To customize the off track name without subclassing, see
	 * <code>customOffTrackName</code>.</p>
	 *
	 * @see #customOffTrackName
	 * @see feathers.core.FeathersControl#styleNameList
	 */
	private var offTrackName:String = DEFAULT_CHILD_NAME_OFF_TRACK;

	/**
	 * The value added to the <code>styleNameList</code> of the thumb. This
	 * variable is <code>private</code> so that sub-classes can customize
	 * the thumb name in their constructors instead of using the default
	 * name defined by <code>DEFAULT_CHILD_NAME_THUMB</code>.
	 *
	 * <p>To customize the thumb name without subclassing, see
	 * <code>customThumbName</code>.</p>
	 *
	 * @see #customThumbName
	 * @see feathers.core.FeathersControl#styleNameList
	 */
	private var thumbName:String = DEFAULT_CHILD_NAME_THUMB;

	/**
	 * The thumb sub-component.
	 *
	 * <p>For internal use in subclasses.</p>
	 *
	 * @see #thumbFactory
	 * @see #createThumb()
	 */
	private var thumb:Button;

	/**
	 * The "on" text renderer sub-component.
	 *
	 * @see #labelFactory
	 */
	private var onTextRenderer:ITextRenderer;

	/**
	 * The "off" text renderer sub-component.
	 *
	 * <p>For internal use in subclasses.</p>
	 *
	 * @see #labelFactory
	 */
	private var offTextRenderer:ITextRenderer;

	/**
	 * The "on" track sub-component.
	 *
	 * <p>For internal use in subclasses.</p>
	 *
	 * @see #onTrackFactory
	 * @see #createOnTrack()
	 */
	private var onTrack:Button;

	/**
	 * The "off" track sub-component.
	 *
	 * <p>For internal use in subclasses.</p>
	 *
	 * @see #offTrackFactory
	 * @see #createOffTrack()
	 */
	private var offTrack:Button;

	/**
	 * @private
	 */
	override private function get_defaultStyleProvider():IStyleProvider
	{
		return ToggleSwitch.globalStyleProvider;
	}

	/**
	 * @private
	 */
	private var _paddingRight:Float = 0;

	/**
	 * The minimum space, in pixels, between the switch's right edge and the
	 * switch's content.
	 *
	 * <p>In the following example, the toggle switch's right padding is
	 * set to 20 pixels:</p>
	 *
	 * <listing version="3.0">
	 * toggle.paddingRight = 20;</listing>
	 *
	 * @default 0
	 */
	public var paddingRight(get, set):Float;
	public function get_paddingRight():Float
	{
		return this._paddingRight;
	}

	/**
	 * @private
	 */
	public function set_paddingRight(value:Float):Float
	{
		if(this._paddingRight == value)
		{
			return;
		}
		this._paddingRight = value;
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _paddingLeft:Float = 0;

	/**
	 * The minimum space, in pixels, between the switch's left edge and the
	 * switch's content.
	 *
	 * <p>In the following example, the toggle switch's left padding is
	 * set to 20 pixels:</p>
	 *
	 * <listing version="3.0">
	 *
	 *
	 * <listing version="3.0">
	 * toggle.customOnTrackName = "my-custom-on-track";</listing>.paddingLeft = 20;</listing>
	 *
	 * @default 0
	 */
	public var paddingLeft(get, set):Float;
	public function get_paddingLeft():Float
	{
		return this._paddingLeft;
	}

	/**
	 * @private
	 */
	public function set_paddingLeft(value:Float):Float
	{
		if(this._paddingLeft == value)
		{
			return;
		}
		this._paddingLeft = value;
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _showLabels:Bool = true;

	/**
	 * Determines if the labels should be drawn. The onTrackSkin and
	 * offTrackSkin backgrounds may include the text instead.
	 *
	 * <p>In the following example, the toggle switch's labels are hidden:</p>
	 *
	 * <listing version="3.0">
	 * toggle.showLabels = false;</listing>
	 *
	 * @default true
	 */
	public var showLabels(get, set):Bool;
	public function get_showLabels():Bool
	{
		return _showLabels;
	}

	/**
	 * @private
	 */
	public function set_showLabels(value:Bool):Bool
	{
		if(this._showLabels == value)
		{
			return;
		}
		this._showLabels = value;
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _showThumb:Bool = true;

	/**
	 * Determines if the thumb should be displayed. This stops interaction
	 * while still displaying the background.
	 *
	 * <p>In the following example, the toggle switch's thumb is hidden:</p>
	 *
	 * <listing version="3.0">
	 * toggle.showThumb = false;</listing>
	 *
	 * @default true
	 */
	public var showThumb(get, set):Bool;
	public function get_showThumb():Bool
	{
		return this._showThumb;
	}

	/**
	 * @private
	 */
	public function set_showThumb(value:Bool):Bool
	{
		if(this._showThumb == value)
		{
			return;
		}
		this._showThumb = value;
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _trackLayoutMode:String = TRACK_LAYOUT_MODE_SINGLE;

	[Inspectable(type="String",enumeration="single,onOff")]
	/**
	 * Determines how the on and off track skins are positioned and sized.
	 *
	 * <p>In the following example, the toggle switch's track layout mode is
	 * updated to use two tracks:</p>
	 *
	 * <listing version="3.0">
	 * toggle.trackLayoutMode = ToggleSwitch.TRACK_LAYOUT_MODE_ON_OFF;</listing>
	 *
	 * @default ToggleSwitch.TRACK_LAYOUT_MODE_SINGLE
	 *
	 * @see #TRACK_LAYOUT_MODE_SINGLE
	 * @see #TRACK_LAYOUT_MODE_ON_OFF
	 */
	public var trackLayoutMode(get, set):String;
	public function get_trackLayoutMode():String
	{
		return this._trackLayoutMode;
	}

	/**
	 * @private
	 */
	public function set_trackLayoutMode(value:String):String
	{
		if(this._trackLayoutMode == value)
		{
			return;
		}
		this._trackLayoutMode = value;
		this.invalidate(FeathersControl.INVALIDATION_FLAG_LAYOUT);
	}

	/**
	 * @private
	 */
	private var _defaultLabelProperties:PropertyProxy;

	/**
	 * The default label properties are a set of key/value pairs to be
	 * passed down to the toggle switch's label text renderers, and it is
	 * used when no specific properties are defined for a specific label
	 * text renderer's current state. The label text renderers are <code>ITextRenderer</code>
	 * instances. The available properties depend on which <code>ITextRenderer</code>
	 * implementation is returned by <code>labelFactory</code>. The most
	 * common implementations are <code>BitmapFontTextRenderer</code> and
	 * <code>TextFieldTextRenderer</code>.
	 *
	 * <p>In the following example, the toggle switch's default label
	 * properties are updated (this example assumes that the label text
	 * renderers are of type <code>TextFieldTextRenderer</code>):</p>
	 *
	 * <listing version="3.0">
	 * toggle.defaultLabelProperties.textFormat = new TextFormat( "Source Sans Pro", 16, 0x333333 );
	 * toggle.defaultLabelProperties.embedFonts = true;</listing>
	 *
	 * @default null
	 *
	 * @see #labelFactory
	 * @see feathers.core.ITextRenderer
	 * @see feathers.controls.text.BitmapFontTextRenderer
	 * @see feathers.controls.text.TextFieldTextRenderer
	 * @see #onLabelProperties
	 * @see #offLabelProperties
	 * @see #disabledLabelProperties
	 */
	public var defaultLabelProperties(get, set):Dynamic;
	public function get_defaultLabelProperties():Dynamic
	{
		if(!this._defaultLabelProperties)
		{
			this._defaultLabelProperties = new PropertyProxy(childProperties_onChange);
		}
		return this._defaultLabelProperties;
	}

	/**
	 * @private
	 */
	public function set_defaultLabelProperties(value:Dynamic):Dynamic
	{
		if(!(Std.is(value, PropertyProxy)))
		{
			value = PropertyProxy.fromObject(value);
		}
		if(this._defaultLabelProperties)
		{
			this._defaultLabelProperties.removeOnChangeCallback(childProperties_onChange);
		}
		this._defaultLabelProperties = PropertyProxy(value);
		if(this._defaultLabelProperties)
		{
			this._defaultLabelProperties.addOnChangeCallback(childProperties_onChange);
		}
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _disabledLabelProperties:PropertyProxy;

	/**
	 * A set of key/value pairs to be passed down to the toggle switch's
	 * label text renderers when the toggle switch is disabled. The label
	 * text renderers are <code>ITextRenderer</code> instances. The
	 * available properties depend on which <code>ITextRenderer</code>
	 * implementation is returned by <code>labelFactory</code>. The most
	 * common implementations are <code>BitmapFontTextRenderer</code> and
	 * <code>TextFieldTextRenderer</code>.
	 *
	 * <p>In the following example, the toggle switch's disabled label
	 * properties are updated (this example assumes that the label text
	 * renderers are of type <code>TextFieldTextRenderer</code>):</p>
	 *
	 * <listing version="3.0">
	 * toggle.disabledLabelProperties.textFormat = new TextFormat( "Source Sans Pro", 16, 0x333333 );
	 * toggle.disabledLabelProperties.embedFonts = true;</listing>
	 *
	 * @default null
	 *
	 * @see #labelFactory
	 * @see feathers.core.ITextRenderer
	 * @see feathers.controls.text.BitmapFontTextRenderer
	 * @see feathers.controls.text.TextFieldTextRenderer
	 * @see #defaultLabelProperties
	 */
	public var disabledLabelProperties(get, set):Dynamic;
	public function get_disabledLabelProperties():Dynamic
	{
		if(!this._disabledLabelProperties)
		{
			this._disabledLabelProperties = new PropertyProxy(childProperties_onChange);
		}
		return this._disabledLabelProperties;
	}

	/**
	 * @private
	 */
	public function set_disabledLabelProperties(value:Dynamic):Dynamic
	{
		if(!(Std.is(value, PropertyProxy)))
		{
			value = PropertyProxy.fromObject(value);
		}
		if(this._disabledLabelProperties)
		{
			this._disabledLabelProperties.removeOnChangeCallback(childProperties_onChange);
		}
		this._disabledLabelProperties = PropertyProxy(value);
		if(this._disabledLabelProperties)
		{
			this._disabledLabelProperties.addOnChangeCallback(childProperties_onChange);
		}
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _onLabelProperties:PropertyProxy;

	/**
	 * A set of key/value pairs to be passed down to the toggle switch's
	 * ON label text renderer. If <code>null</code>, then
	 * <code>defaultLabelProperties</code> is used instead. The label text
	 * renderers are <code>ITextRenderer</code> instances. The available
	 * properties depend on which <code>ITextRenderer</code> implementation
	 * is returned by <code>labelFactory</code>. The most common
	 * implementations are <code>BitmapFontTextRenderer</code> and
	 * <code>TextFieldTextRenderer</code>.
	 *
	 * <p>In the following example, the toggle switch's on label properties
	 * are updated (this example assumes that the on label text renderer is a
	 * <code>TextFieldTextRenderer</code>):</p>
	 *
	 * <listing version="3.0">
	 * toggle.onLabelProperties.textFormat = new TextFormat( "Source Sans Pro", 16, 0x333333 );
	 * toggle.onLabelProperties.embedFonts = true;</listing>
	 *
	 * @default null
	 *
	 * @see #labelFactory
	 * @see feathers.core.ITextRenderer
	 * @see feathers.controls.text.BitmapFontTextRenderer
	 * @see feathers.controls.text.TextFieldTextRenderer
	 * @see #defaultLabelProperties
	 */
	public var onLabelProperties(get, set):Dynamic;
	public function get_onLabelProperties():Dynamic
	{
		if(!this._onLabelProperties)
		{
			this._onLabelProperties = new PropertyProxy(childProperties_onChange);
		}
		return this._onLabelProperties;
	}

	/**
	 * @private
	 */
	public function set_onLabelProperties(value:Dynamic):Dynamic
	{
		if(!(Std.is(value, PropertyProxy)))
		{
			value = PropertyProxy.fromObject(value);
		}
		if(this._onLabelProperties)
		{
			this._onLabelProperties.removeOnChangeCallback(childProperties_onChange);
		}
		this._onLabelProperties = PropertyProxy(value);
		if(this._onLabelProperties)
		{
			this._onLabelProperties.addOnChangeCallback(childProperties_onChange);
		}
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _offLabelProperties:PropertyProxy;

	/**
	 * A set of key/value pairs to be passed down to the toggle switch's
	 * OFF label text renderer. If <code>null</code>, then
	 * <code>defaultLabelProperties</code> is used instead. The label text
	 * renderers are <code>ITextRenderer</code> instances. The available
	 * properties depend on which <code>ITextRenderer</code> implementation
	 * is returned by <code>labelFactory</code>. The most common
	 * implementations are <code>BitmapFontTextRenderer</code> and
	 * <code>TextFieldTextRenderer</code>.
	 *
	 * <p>In the following example, the toggle switch's off label properties
	 * are updated (this example assumes that the off label text renderer is a
	 * <code>TextFieldTextRenderer</code>):</p>
	 *
	 * <listing version="3.0">
	 * toggle.offLabelProperties.textFormat = new TextFormat( "Source Sans Pro", 16, 0x333333 );
	 * toggle.offLabelProperties.embedFonts = true;</listing>
	 *
	 * @default null
	 *
	 * @see #labelFactory
	 * @see feathers.core.ITextRenderer
	 * @see feathers.controls.text.BitmapFontTextRenderer
	 * @see feathers.controls.text.TextFieldTextRenderer
	 * @see #defaultLabelProperties
	 */
	public var offLabelProperties(get, set):Dynamic;
	public function get_offLabelProperties():Dynamic
	{
		if(!this._offLabelProperties)
		{
			this._offLabelProperties = new PropertyProxy(childProperties_onChange);
		}
		return this._offLabelProperties;
	}

	/**
	 * @private
	 */
	public function set_offLabelProperties(value:Dynamic):Dynamic
	{
		if(!(Std.is(value, PropertyProxy)))
		{
			value = PropertyProxy.fromObject(value);
		}
		if(this._offLabelProperties)
		{
			this._offLabelProperties.removeOnChangeCallback(childProperties_onChange);
		}
		this._offLabelProperties = PropertyProxy(value);
		if(this._offLabelProperties)
		{
			this._offLabelProperties.addOnChangeCallback(childProperties_onChange);
		}
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _labelAlign:String = LABEL_ALIGN_BASELINE;

	[Inspectable(type="String",enumeration="baseline,middle")]
	/**
	 * The vertical alignment of the label.
	 *
	 * <p>In the following example, the toggle switch's label alignment is
	 * updated:</p>
	 *
	 * <listing version="3.0">
	 * toggle.labelAlign = ToggleSwitch.LABEL_ALIGN_MIDDLE;</listing>
	 *
	 * @default ToggleSwitch.LABEL_ALIGN_BASELINE
	 *
	 * @see #LABEL_ALIGN_BASELINE
	 * @see #LABEL_ALIGN_MIDDLE
	 */
	public var labelAlign(get, set):String;
	public function get_labelAlign():String
	{
		return this._labelAlign;
	}

	/**
	 * @private
	 */
	public function set_labelAlign(value:String):String
	{
		if(this._labelAlign == value)
		{
			return;
		}
		this._labelAlign = value;
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _labelFactory:Dynamic;

	/**
	 * A function used to instantiate the toggle switch's label text
	 * renderer sub-components, if specific factories for those label text
	 * renderers are not provided. The label text renderers must be
	 * instances of <code>ITextRenderer</code>. This factory can be used to
	 * change properties of the label text renderers when they are first
	 * created. For instance, if you are skinning Feathers components
	 * without a theme, you might use this factory to style the label text
	 * renderers.
	 *
	 * <p>The factory should have the following function signature:</p>
	 * <pre>function():ITextRenderer</pre>
	 *
	 * <p>In the following example, the toggle switch uses a custom label
	 * factory:</p>
	 *
	 * <listing version="3.0">
	 * toggle.labelFactory = function():ITextRenderer
	 * {
	 *     return new TextFieldTextRenderer();
	 * }</listing>
	 *
	 * @default null
	 *
	 * @see #onLabelFactory
	 * @see #offLabelFactory
	 * @see feathers.core.ITextRenderer
	 * @see feathers.core.FeathersControl#defaultTextRendererFactory
	 */
	public var labelFactory(get, set):Dynamic;
	public function get_labelFactory():Dynamic
	{
		return this._labelFactory;
	}

	/**
	 * @private
	 */
	public function set_labelFactory(value:Dynamic):Dynamic
	{
		if(this._labelFactory == value)
		{
			return;
		}
		this._labelFactory = value;
		this.invalidate(FeathersControl.INVALIDATION_FLAG_TEXT_RENDERER);
	}

	/**
	 * @private
	 */
	private var _onLabelFactory:Dynamic;

	/**
	 * A function used to instantiate the toggle switch's on label text
	 * renderer sub-component. The on label text renderer must be an
	 * instance of <code>ITextRenderer</code>. This factory can be used to
	 * change properties of the on label text renderer when it is first
	 * created. For instance, if you are skinning Feathers components
	 * without a theme, you might use this factory to style the on label
	 * text renderer.
	 *
	 * <p>If an <code>onLabelFactory</code> is not provided, the default
	 * <code>labelFactory</code> will be used.</p>
	 *
	 * <p>The factory should have the following function signature:</p>
	 * <pre>function():ITextRenderer</pre>
	 *
	 * <p>In the following example, the toggle switch uses a custom on label
	 * factory:</p>
	 *
	 * <listing version="3.0">
	 * toggle.onLabelFactory = function():ITextRenderer
	 * {
	 *     return new TextFieldTextRenderer();
	 * }</listing>
	 *
	 * @default null
	 *
	 * @see #labelFactory
	 * @see #offLabelFactory
	 * @see feathers.core.ITextRenderer
	 * @see feathers.core.FeathersControl#defaultTextRendererFactory
	 */
	public var onLabelFactory(get, set):Dynamic;
	public function get_onLabelFactory():Dynamic
	{
		return this._onLabelFactory;
	}

	/**
	 * @private
	 */
	public function set_onLabelFactory(value:Dynamic):Dynamic
	{
		if(this._onLabelFactory == value)
		{
			return;
		}
		this._onLabelFactory = value;
		this.invalidate(FeathersControl.INVALIDATION_FLAG_TEXT_RENDERER);
	}

	/**
	 * @private
	 */
	private var _offLabelFactory:Dynamic;

	/**
	 * A function used to instantiate the toggle switch's off label text
	 * renderer sub-component. The off label text renderer must be an
	 * instance of <code>ITextRenderer</code>. This factory can be used to
	 * change properties of the off label text renderer when it is first
	 * created. For instance, if you are skinning Feathers components
	 * without a theme, you might use this factory to style the off label
	 * text renderer.
	 *
	 * <p>If an <code>offLabelFactory</code> is not provided, the default
	 * <code>labelFactory</code> will be used.</p>
	 *
	 * <p>The factory should have the following function signature:</p>
	 * <pre>function():ITextRenderer</pre>
	 *
	 * <p>In the following example, the toggle switch uses a custom on label
	 * factory:</p>
	 *
	 * <listing version="3.0">
	 * toggle.offLabelFactory = function():ITextRenderer
	 * {
	 *     return new TextFieldTextRenderer();
	 * }</listing>
	 *
	 * @default null
	 *
	 * @see #labelFactory
	 * @see #onLabelFactory
	 * @see feathers.core.ITextRenderer
	 * @see feathers.core.FeathersControl#defaultTextRendererFactory
	 */
	public var offLabelFactory(get, set):Dynamic;
	public function get_offLabelFactory():Dynamic
	{
		return this._offLabelFactory;
	}

	/**
	 * @private
	 */
	public function set_offLabelFactory(value:Dynamic):Dynamic
	{
		if(this._offLabelFactory == value)
		{
			return;
		}
		this._offLabelFactory = value;
		this.invalidate(FeathersControl.INVALIDATION_FLAG_TEXT_RENDERER);
	}

	/**
	 * @private
	 */
	private var onTrackSkinOriginalWidth:Float = Math.NaN;

	/**
	 * @private
	 */
	private var onTrackSkinOriginalHeight:Float = Math.NaN;

	/**
	 * @private
	 */
	private var offTrackSkinOriginalWidth:Float = Math.NaN;

	/**
	 * @private
	 */
	private var offTrackSkinOriginalHeight:Float = Math.NaN;

	/**
	 * @private
	 */
	private var _isSelected:Bool = false;

	/**
	 * Indicates if the toggle switch is selected (ON) or not (OFF).
	 *
	 * <p>In the following example, the toggle switch is selected:</p>
	 *
	 * <listing version="3.0">
	 * toggle.isSelected = true;</listing>
	 *
	 * @default false
	 *
	 * @see #setSelectionWithAnimation()
	 */
	public var isSelected(get, set):Bool;
	public function get_isSelected():Bool
	{
		return this._isSelected;
	}

	/**
	 * @private
	 */
	public function set_isSelected(value:Bool):Bool
	{
		this._animateSelectionChange = false;
		if(this._isSelected == value)
		{
			return;
		}
		this._isSelected = value;
		this.invalidate(FeathersControl.INVALIDATION_FLAG_SELECTED);
		this.dispatchEventWith(Event.CHANGE);
	}

	/**
	 * @private
	 */
	private var _toggleThumbSelection:Bool = false;

	/**
	 * Determines if the <code>isSelected</code> property of the thumb
	 * is updated to match the <code>isSelected</code> property of the
	 * toggle switch, if the class used to create the thumb implements the
	 * <code>IToggle</code> interface. Useful for skinning to provide a
	 * different appearance for the thumb based on whether the toggle switch
	 * is selected or not.
	 *
	 * <p>In the following example, the thumb selection is toggled:</p>
	 *
	 * <listing version="3.0">
	 * toggle.toggleThumbSelection = true;</listing>
	 *
	 * @default false
	 *
	 * @see feathers.core.IToggle
	 * @see feathers.controls.ToggleButton
	 */
	public var toggleThumbSelection(get, set):Bool;
	public function get_toggleThumbSelection():Bool
	{
		return this._toggleThumbSelection;
	}

	/**
	 * @private
	 */
	public function set_toggleThumbSelection(value:Bool):Bool
	{
		if(this._toggleThumbSelection == value)
		{
			return;
		}
		this._toggleThumbSelection = value;
		this.invalidate(FeathersControl.INVALIDATION_FLAG_SELECTED);
	}

	/**
	 * @private
	 */
	private var _toggleDuration:Float = 0.15;

	/**
	 * The duration, in seconds, of the animation when the toggle switch
	 * is toggled and animates the position of the thumb.
	 *
	 * <p>In the following example, the duration of the toggle switch thumb
	 * animation is updated:</p>
	 *
	 * <listing version="3.0">
	 * toggle.toggleDuration = 0.5;</listing>
	 *
	 * @default 0.15
	 */
	public var toggleDuration(get, set):Float;
	public function get_toggleDuration():Float
	{
		return this._toggleDuration;
	}

	/**
	 * @private
	 */
	public function set_toggleDuration(value:Float):Float
	{
		this._toggleDuration = value;
	}

	/**
	 * @private
	 */
	private var _toggleEase:Dynamic = Transitions.EASE_OUT;

	/**
	 * The easing function used for toggle animations.
	 *
	 * <p>In the following example, the easing function used by the toggle
	 * switch's thumb animation is updated:</p>
	 *
	 * <listing version="3.0">
	 * toggle.toggleEase = Transitions.EASE_IN_OUT;</listing>
	 *
	 * @default starling.animation.Transitions.EASE_OUT
	 *
	 * @see http://doc.starling-framework.org/core/starling/animation/Transitions.html starling.animation.Transitions
	 */
	public var toggleEase(get, set):Dynamic;
	public function get_toggleEase():Dynamic
	{
		return this._toggleEase;
	}

	/**
	 * @private
	 */
	public function set_toggleEase(value:Dynamic):Dynamic
	{
		this._toggleEase = value;
	}

	/**
	 * @private
	 */
	private var _onText:String = "ON";

	/**
	 * The text to display in the ON label.
	 *
	 * <p>In the following example, the toggle switch's on label text is
	 * updated:</p>
	 *
	 * <listing version="3.0">
	 * toggle.onText = "on";</listing>
	 *
	 * @default "ON"
	 */
	public var onText(get, set):String;
	public function get_onText():String
	{
		return this._onText;
	}

	/**
	 * @private
	 */
	public function set_onText(value:String):String
	{
		if(value == null)
		{
			value = "";
		}
		if(this._onText == value)
		{
			return;
		}
		this._onText = value;
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _offText:String = "OFF";

	/**
	 * The text to display in the OFF label.
	 *
	 * <p>In the following example, the toggle switch's off label text is
	 * updated:</p>
	 *
	 * <listing version="3.0">
	 * toggle.offText = "off";</listing>
	 *
	 * @default "OFF"
	 */
	public var offText(get, set):String;
	public function get_offText():String
	{
		return this._offText;
	}

	/**
	 * @private
	 */
	public function set_offText(value:String):String
	{
		if(value == null)
		{
			value = "";
		}
		if(this._offText == value)
		{
			return;
		}
		this._offText = value;
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _toggleTween:Tween;

	/**
	 * @private
	 */
	private var _ignoreTapHandler:Bool = false;

	/**
	 * @private
	 */
	private var _touchPointID:Int = -1;

	/**
	 * @private
	 */
	private var _thumbStartX:Float;

	/**
	 * @private
	 */
	private var _touchStartX:Float;

	/**
	 * @private
	 */
	private var _animateSelectionChange:Bool = false;

	/**
	 * @private
	 */
	private var _onTrackFactory:Dynamic;

	/**
	 * A function used to generate the toggle switch's on track
	 * sub-component. The on track must be an instance of <code>Button</code>.
	 * This factory can be used to change properties on the on track when it
	 * is first created. For instance, if you are skinning Feathers
	 * components without a theme, you might use this factory to set skins
	 * and other styles on the on track.
	 *
	 * <p>The function should have the following signature:</p>
	 * <pre>function():Button</pre>
	 *
	 * <p>In the following example, a custom on track factory is passed to
	 * the toggle switch:</p>
	 *
	 * <listing version="3.0">
	 * toggle.onTrackFactory = function():Button
	 * {
	 *     var onTrack:Button = new Button();
	 *     onTrack.defaultSkin = new Image( texture );
	 *     return onTrack;
	 * };</listing>
	 *
	 * @default null
	 *
	 * @see feathers.controls.Button
	 * @see #onTrackProperties
	 */
	public var onTrackFactory(get, set):Dynamic;
	public function get_onTrackFactory():Dynamic
	{
		return this._onTrackFactory;
	}

	/**
	 * @private
	 */
	public function set_onTrackFactory(value:Dynamic):Dynamic
	{
		if(this._onTrackFactory == value)
		{
			return;
		}
		this._onTrackFactory = value;
		this.invalidate(INVALIDATION_FLAG_ON_TRACK_FACTORY);
	}

	/**
	 * @private
	 */
	private var _customOnTrackName:String;

	/**
	 * A name to add to the toggle switch's on track sub-component. Typically
	 * used by a theme to provide different skins to different toggle switches.
	 *
	 * <p>In the following example, a custom on track name is passed to
	 * the toggle switch:</p>
	 *
	 * <listing version="3.0">
	 * toggle.customOnTrackName = "my-custom-on-track";</listing>
	 *
	 * <p>In your theme, you can target this item renderer name to provide
	 * different skins than the default style:</p>
	 *
	 * <listing version="3.0">
	 * getStyleProviderForClass( Button ).setFunctionForStyleName( "my-custom-on-track", setCustomOnTrackStyles );</listing>
	 *
	 * @default null
	 *
	 * @see #DEFAULT_CHILD_NAME_ON_TRACK
	 * @see feathers.core.FeathersControl#styleNameList
	 * @see #onTrackFactory
	 * @see #onTrackProperties
	 */
	public var customOnTrackName(get, set):String;
	public function get_customOnTrackName():String
	{
		return this._customOnTrackName;
	}

	/**
	 * @private
	 */
	public function set_customOnTrackName(value:String):String
	{
		if(this._customOnTrackName == value)
		{
			return;
		}
		this._customOnTrackName = value;
		this.invalidate(INVALIDATION_FLAG_ON_TRACK_FACTORY);
	}

	/**
	 * @private
	 */
	private var _onTrackProperties:PropertyProxy;

	/**
	 * A set of key/value pairs to be passed down to the toggle switch's on
	 * track sub-component. The on track is a
	 * <code>feathers.controls.Button</code> instance.
	 *
	 * <p>If the subcomponent has its own subcomponents, their properties
	 * can be set too, using attribute <code>&#64;</code> notation. For example,
	 * to set the skin on the thumb which is in a <code>SimpleScrollBar</code>,
	 * which is in a <code>List</code>, you can use the following syntax:</p>
	 * <pre>list.verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);</pre>
	 *
	 * <p>Setting properties in a <code>onTrackFactory</code> function
	 * instead of using <code>onTrackProperties</code> will result in
	 * better performance.</p>
	 *
	 * <p>In the following example, the toggle switch's on track properties
	 * are updated:</p>
	 *
	 * <listing version="3.0">
	 * toggle.onTrackProperties.defaultSkin = new Image( texture );</listing>
	 *
	 * @default null
	 * 
	 * @see feathers.controls.Button
	 * @see #onTrackFactory
	 */
	public var onTrackProperties(get, set):Dynamic;
	public function get_onTrackProperties():Dynamic
	{
		if(!this._onTrackProperties)
		{
			this._onTrackProperties = new PropertyProxy(childProperties_onChange);
		}
		return this._onTrackProperties;
	}

	/**
	 * @private
	 */
	public function set_onTrackProperties(value:Dynamic):Dynamic
	{
		if(this._onTrackProperties == value)
		{
			return;
		}
		if(!value)
		{
			value = new PropertyProxy();
		}
		if(!(Std.is(value, PropertyProxy)))
		{
			var newValue:PropertyProxy = new PropertyProxy();
			for (propertyName in value)
			{
				newValue[propertyName] = value[propertyName];
			}
			value = newValue;
		}
		if(this._onTrackProperties)
		{
			this._onTrackProperties.removeOnChangeCallback(childProperties_onChange);
		}
		this._onTrackProperties = PropertyProxy(value);
		if(this._onTrackProperties)
		{
			this._onTrackProperties.addOnChangeCallback(childProperties_onChange);
		}
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _offTrackFactory:Dynamic;

	/**
	 * A function used to generate the toggle switch's off track
	 * sub-component. The off track must be an instance of <code>Button</code>.
	 * This factory can be used to change properties on the off track when it
	 * is first created. For instance, if you are skinning Feathers
	 * components without a theme, you might use this factory to set skins
	 * and other styles on the off track.
	 *
	 * <p>The function should have the following signature:</p>
	 * <pre>function():Button</pre>
	 *
	 * <p>In the following example, a custom off track factory is passed to
	 * the toggle switch:</p>
	 *
	 * <listing version="3.0">
	 * toggle.offTrackFactory = function():Button
	 * {
	 *     var offTrack:Button = new Button();
	 *     offTrack.defaultSkin = new Image( texture );
	 *     return offTrack;
	 * };</listing>
	 *
	 * @default null
	 *
	 * @see feathers.controls.Button
	 * @see #offTrackProperties
	 */
	public var offTrackFactory(get, set):Dynamic;
	public function get_offTrackFactory():Dynamic
	{
		return this._offTrackFactory;
	}

	/**
	 * @private
	 */
	public function set_offTrackFactory(value:Dynamic):Dynamic
	{
		if(this._offTrackFactory == value)
		{
			return;
		}
		this._offTrackFactory = value;
		this.invalidate(INVALIDATION_FLAG_OFF_TRACK_FACTORY);
	}

	/**
	 * @private
	 */
	private var _customOffTrackName:String;

	/**
	 * A name to add to the toggle switch's off track sub-component. Typically
	 * used by a theme to provide different skins to different toggle switches.
	 *
	 * <p>In the following example, a custom off track name is passed to the
	 * toggle switch:</p>
	 *
	 * <listing version="3.0">
	 * toggle.customOnTrackName = "my-custom-off-track";</listing>
	 *
	 * <p>In your theme, you can target this sub-component name to provide
	 * different skins than the default style:</p>
	 *
	 * <listing version="3.0">
	 * getStyleProviderForClass( Button ).setFunctionForStyleName( "my-custom-off-track", setCustomOffTrackStyles );</listing>
	 *
	 * @default null
	 *
	 * @see #DEFAULT_CHILD_NAME_OFF_TRACK
	 * @see feathers.core.FeathersControl#styleNameList
	 * @see #offTrackFactory
	 * @see #offTrackProperties
	 */
	public var customOffTrackName(get, set):String;
	public function get_customOffTrackName():String
	{
		return this._customOffTrackName;
	}

	/**
	 * @private
	 */
	public function set_customOffTrackName(value:String):String
	{
		if(this._customOffTrackName == value)
		{
			return;
		}
		this._customOffTrackName = value;
		this.invalidate(INVALIDATION_FLAG_OFF_TRACK_FACTORY);
	}

	/**
	 * @private
	 */
	private var _offTrackProperties:PropertyProxy;

	/**
	 * A set of key/value pairs to be passed down to the toggle switch's off
	 * track sub-component. The off track is a
	 * <code>feathers.controls.Button</code> instance.
	 *
	 * <p>If the subcomponent has its own subcomponents, their properties
	 * can be set too, using attribute <code>&#64;</code> notation. For example,
	 * to set the skin on the thumb which is in a <code>SimpleScrollBar</code>,
	 * which is in a <code>List</code>, you can use the following syntax:</p>
	 * <pre>list.verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);</pre>
	 *
	 * <p>Setting properties in a <code>offTrackFactory</code> function
	 * instead of using <code>offTrackProperties</code> will result in
	 * better performance.</p>
	 *
	 * <p>In the following example, the toggle switch's off track properties
	 * are updated:</p>
	 *
	 * <listing version="3.0">
	 * toggle.offTrackProperties.defaultSkin = new Image( texture );</listing>
	 *
	 * @default null
	 * 
	 * @see feathers.controls.Button
	 * @see #offTrackFactory
	 */
	public var offTrackProperties(get, set):Dynamic;
	public function get_offTrackProperties():Dynamic
	{
		if(!this._offTrackProperties)
		{
			this._offTrackProperties = new PropertyProxy(childProperties_onChange);
		}
		return this._offTrackProperties;
	}

	/**
	 * @private
	 */
	public function set_offTrackProperties(value:Dynamic):Dynamic
	{
		if(this._offTrackProperties == value)
		{
			return;
		}
		if(!value)
		{
			value = new PropertyProxy();
		}
		if(!(Std.is(value, PropertyProxy)))
		{
			var newValue:PropertyProxy = new PropertyProxy();
			for (propertyName in value)
			{
				newValue[propertyName] = value[propertyName];
			}
			value = newValue;
		}
		if(this._offTrackProperties)
		{
			this._offTrackProperties.removeOnChangeCallback(childProperties_onChange);
		}
		this._offTrackProperties = PropertyProxy(value);
		if(this._offTrackProperties)
		{
			this._offTrackProperties.addOnChangeCallback(childProperties_onChange);
		}
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _thumbFactory:Dynamic;

	/**
	 * A function used to generate the toggle switch's thumb sub-component.
	 * This can be used to change properties on the thumb when it is first
	 * created. For instance, if you are skinning Feathers components
	 * without a theme, you might use <code>thumbFactory</code> to set
	 * skins and text styles on the thumb.
	 *
	 * <p>The function should have the following signature:</p>
	 * <pre>function():Button</pre>
	 *
	 * <p>In the following example, a custom thumb factory is passed to the
	 * toggle switch:</p>
	 *
	 * <listing version="3.0">
	 * toggle.thumbFactory = function():Button
	 * {
	 *     var button:Button = new Button();
	 *     button.defaultSkin = new Image( texture );
	 *     return button;
	 * };</listing>
	 *
	 * @default null
	 *
	 * @see #thumbProperties
	 */
	public var thumbFactory(get, set):Dynamic;
	public function get_thumbFactory():Dynamic
	{
		return this._thumbFactory;
	}

	/**
	 * @private
	 */
	public function set_thumbFactory(value:Dynamic):Dynamic
	{
		if(this._thumbFactory == value)
		{
			return;
		}
		this._thumbFactory = value;
		this.invalidate(INVALIDATION_FLAG_THUMB_FACTORY);
	}

	/**
	 * @private
	 */
	private var _customThumbName:String;

	/**
	 * A name to add to the toggle switch's thumb sub-component. Typically
	 * used by a theme to provide different skins to different toggle switches.
	 *
	 * <p>In the following example, a custom thumb name is passed to the
	 * toggle switch:</p>
	 *
	 * <listing version="3.0">
	 * toggle.customThumbName = "my-custom-thumb";</listing>
	 *
	 * <p>In your theme, you can target this sub-component name to provide
	 * different skins than the default style:</p>
	 *
	 * <listing version="3.0">
	 * getStyleProviderForClass( Button ).setFunctionForStyleName( "my-custom-thumb", setCustomThumbStyles );</listing>
	 *
	 * @default null
	 *
	 * @see #DEFAULT_CHILD_NAME_THUMB
	 * @see feathers.core.FeathersControl#styleNameList
	 * @see #thumbFactory
	 * @see #thumbProperties
	 */
	public var customThumbName(get, set):String;
	public function get_customThumbName():String
	{
		return this._customThumbName;
	}

	/**
	 * @private
	 */
	public function set_customThumbName(value:String):String
	{
		if(this._customThumbName == value)
		{
			return;
		}
		this._customThumbName = value;
		this.invalidate(INVALIDATION_FLAG_THUMB_FACTORY);
	}

	/**
	 * @private
	 */
	private var _thumbProperties:PropertyProxy;

	/**
	 * A set of key/value pairs to be passed down to the toggle switch's
	 * thumb sub-component. The thumb is a
	 * <code>feathers.controls.Button</code> instance.
	 *
	 * <p>If the subcomponent has its own subcomponents, their properties
	 * can be set too, using attribute <code>&#64;</code> notation. For example,
	 * to set the skin on the thumb which is in a <code>SimpleScrollBar</code>,
	 * which is in a <code>List</code>, you can use the following syntax:</p>
	 * <pre>list.verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);</pre>
	 *
	 * <p>Setting properties in a <code>thumbFactory</code> function instead
	 * of using <code>thumbProperties</code> will result in better
	 * performance.</p>
	 *
	 * <p>In the following example, the toggle switch's thumb properties
	 * are updated:</p>
	 *
	 * <listing version="3.0">
	 * toggle.thumbProperties.defaultSkin = new Image( texture );</listing>
	 *
	 * @default null
	 * 
	 * @see feathers.controls.Button
	 * @see #thumbFactory
	 */
	public var thumbProperties(get, set):Dynamic;
	public function get_thumbProperties():Dynamic
	{
		if(!this._thumbProperties)
		{
			this._thumbProperties = new PropertyProxy(childProperties_onChange);
		}
		return this._thumbProperties;
	}

	/**
	 * @private
	 */
	public function set_thumbProperties(value:Dynamic):Dynamic
	{
		if(this._thumbProperties == value)
		{
			return;
		}
		if(!value)
		{
			value = new PropertyProxy();
		}
		if(!(Std.is(value, PropertyProxy)))
		{
			var newValue:PropertyProxy = new PropertyProxy();
			for (propertyName in value)
			{
				newValue[propertyName] = value[propertyName];
			}
			value = newValue;
		}
		if(this._thumbProperties)
		{
			this._thumbProperties.removeOnChangeCallback(childProperties_onChange);
		}
		this._thumbProperties = PropertyProxy(value);
		if(this._thumbProperties)
		{
			this._thumbProperties.addOnChangeCallback(childProperties_onChange);
		}
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * Changes the <code>isSelected</code> property, but animates the thumb
	 * to the new position, as if the user tapped the toggle switch.
	 *
	 * @see #isSelected
	 */
	public function setSelectionWithAnimation(isSelected:Bool):Void
	{
		if(this._isSelected == isSelected)
		{
			return;
		}
		this.isSelected = isSelected;
		this._animateSelectionChange = true;
	}

	/**
	 * @private
	 */
	override private function draw():Void
	{
		var selectionInvalid:Bool = this.isInvalid(FeathersControl.INVALIDATION_FLAG_SELECTED);
		var stylesInvalid:Bool = this.isInvalid(INVALIDATION_FLAG_STYLES);
		var sizeInvalid:Bool = this.isInvalid(INVALIDATION_FLAG_SIZE);
		var stateInvalid:Bool = this.isInvalid(INVALIDATION_FLAG_STATE);
		var focusInvalid:Bool = this.isInvalid(FeathersControl.INVALIDATION_FLAG_FOCUS);
		var layoutInvalid:Bool = this.isInvalid(FeathersControl.INVALIDATION_FLAG_LAYOUT);
		var textRendererInvalid:Bool = this.isInvalid(FeathersControl.INVALIDATION_FLAG_TEXT_RENDERER);
		var thumbFactoryInvalid:Bool = this.isInvalid(INVALIDATION_FLAG_THUMB_FACTORY);
		var onTrackFactoryInvalid:Bool = this.isInvalid(INVALIDATION_FLAG_ON_TRACK_FACTORY);
		var offTrackFactoryInvalid:Bool = this.isInvalid(INVALIDATION_FLAG_OFF_TRACK_FACTORY);

		if(thumbFactoryInvalid)
		{
			this.createThumb();
		}

		if(onTrackFactoryInvalid)
		{
			this.createOnTrack();
		}

		if(offTrackFactoryInvalid || layoutInvalid)
		{
			this.createOffTrack();
		}

		if(textRendererInvalid)
		{
			this.createLabels();
		}

		if(textRendererInvalid || stylesInvalid || stateInvalid)
		{
			this.refreshOnLabelStyles();
			this.refreshOffLabelStyles();
		}

		if(thumbFactoryInvalid || stylesInvalid)
		{
			this.refreshThumbStyles();
		}
		if(onTrackFactoryInvalid || stylesInvalid)
		{
			this.refreshOnTrackStyles();
		}
		if((offTrackFactoryInvalid || layoutInvalid || stylesInvalid) && this.offTrack)
		{
			this.refreshOffTrackStyles();
		}

		if(thumbFactoryInvalid || stateInvalid)
		{
			this.thumb.isEnabled = this._isEnabled;
		}
		if(onTrackFactoryInvalid || stateInvalid)
		{
			this.onTrack.isEnabled = this._isEnabled;
		}
		if((offTrackFactoryInvalid || layoutInvalid || stateInvalid) && this.offTrack)
		{
			this.offTrack.isEnabled = this._isEnabled;
		}
		if(textRendererInvalid || stateInvalid)
		{
			this.onTextRenderer.isEnabled = this._isEnabled;
			this.offTextRenderer.isEnabled = this._isEnabled;
		}

		sizeInvalid = this.autoSizeIfNeeded() || sizeInvalid;

		if(sizeInvalid || stylesInvalid || selectionInvalid)
		{
			this.updateSelection();
		}

		this.layoutChildren();

		if(sizeInvalid || focusInvalid)
		{
			this.refreshFocusIndicator();
		}
	}

	/**
	 * If the component's dimensions have not been set explicitly, it will
	 * measure its content and determine an ideal size for itself. If the
	 * <code>explicitWidth</code> or <code>explicitHeight</code> member
	 * variables are set, those value will be used without additional
	 * measurement. If one is set, but not the other, the dimension with the
	 * explicit value will not be measured, but the other non-explicit
	 * dimension will still need measurement.
	 *
	 * <p>Calls <code>setSizeInternal()</code> to set up the
	 * <code>actualWidth</code> and <code>actualHeight</code> member
	 * variables used for layout.</p>
	 *
	 * <p>Meant for internal use, and subclasses may override this function
	 * with a custom implementation.</p>
	 */
	private function autoSizeIfNeeded():Bool
	{
		if(this.onTrackSkinOriginalWidth != this.onTrackSkinOriginalWidth || //isNaN
			this.onTrackSkinOriginalHeight != this.onTrackSkinOriginalHeight) //isNaN
		{
			this.onTrack.validate();
			this.onTrackSkinOriginalWidth = this.onTrack.width;
			this.onTrackSkinOriginalHeight = this.onTrack.height;
		}
		if(this.offTrack)
		{
			if(this.offTrackSkinOriginalWidth != this.offTrackSkinOriginalWidth || //isNaN
				this.offTrackSkinOriginalHeight != this.offTrackSkinOriginalHeight) //isNaN
			{
				this.offTrack.validate();
				this.offTrackSkinOriginalWidth = this.offTrack.width;
				this.offTrackSkinOriginalHeight = this.offTrack.height;
			}
		}

		var needsWidth:Bool = this.explicitWidth != this.explicitWidth; //isNaN
		var needsHeight:Bool = this.explicitHeight != this.explicitHeight; //isNaN
		if(!needsWidth && !needsHeight)
		{
			return false;
		}
		this.thumb.validate();
		var newWidth:Float = this.explicitWidth;
		var newHeight:Float = this.explicitHeight;
		if(needsWidth)
		{
			if(this.offTrack)
			{
				newWidth = Math.min(this.onTrackSkinOriginalWidth, this.offTrackSkinOriginalWidth) + this.thumb.width / 2;
			}
			else
			{
				newWidth = this.onTrackSkinOriginalWidth;
			}
		}
		if(needsHeight)
		{
			if(this.offTrack)
			{
				newHeight = Math.max(this.onTrackSkinOriginalHeight, this.offTrackSkinOriginalHeight);
			}
			else
			{
				newHeight = this.onTrackSkinOriginalHeight;
			}
		}
		return this.setSizeInternal(newWidth, newHeight, false);
	}

	/**
	 * Creates and adds the <code>thumb</code> sub-component and
	 * removes the old instance, if one exists.
	 *
	 * <p>Meant for internal use, and subclasses may override this function
	 * with a custom implementation.</p>
	 *
	 * @see #thumb
	 * @see #thumbFactory
	 * @see #customThumbName
	 */
	private function createThumb():Void
	{
		if(this.thumb)
		{
			this.thumb.removeFromParent(true);
			this.thumb = null;
		}

		var factory:Dynamic = this._thumbFactory != null ? this._thumbFactory : defaultThumbFactory;
		var thumbName:String = this._customThumbName != null ? this._customThumbName : this.thumbName;
		this.thumb = Button(factory());
		this.thumb.styleNameList.add(thumbName);
		this.thumb.keepDownStateOnRollOut = true;
		this.thumb.addEventListener(TouchEvent.TOUCH, thumb_touchHandler);
		this.addChild(this.thumb);
	}

	/**
	 * Creates and adds the <code>onTrack</code> sub-component and
	 * removes the old instance, if one exists.
	 *
	 * <p>Meant for internal use, and subclasses may override this function
	 * with a custom implementation.</p>
	 *
	 * @see #onTrack
	 * @see #onTrackFactory
	 * @see #customOnTrackName
	 */
	private function createOnTrack():Void
	{
		if(this.onTrack)
		{
			this.onTrack.removeFromParent(true);
			this.onTrack = null;
		}

		var factory:Dynamic = this._onTrackFactory != null ? this._onTrackFactory : defaultOnTrackFactory;
		var onTrackName:String = this._customOnTrackName != null ? this._customOnTrackName : this.onTrackName;
		this.onTrack = Button(factory());
		this.onTrack.styleNameList.add(onTrackName);
		this.onTrack.keepDownStateOnRollOut = true;
		this.addChildAt(this.onTrack, 0);
	}

	/**
	 * Creates and adds the <code>offTrack</code> sub-component and
	 * removes the old instance, if one exists. If the off track is not
	 * needed, it will not be created.
	 *
	 * <p>Meant for internal use, and subclasses may override this function
	 * with a custom implementation.</p>
	 *
	 * @see #offTrack
	 * @see #offTrackFactory
	 * @see #customOffTrackName
	 */
	private function createOffTrack():Void
	{
		if(this._trackLayoutMode == TRACK_LAYOUT_MODE_ON_OFF)
		{
			if(this.offTrack)
			{
				this.offTrack.removeFromParent(true);
				this.offTrack = null;
			}
			var factory:Dynamic = this._offTrackFactory != null ? this._offTrackFactory : defaultOffTrackFactory;
			var offTrackName:String = this._customOffTrackName != null ? this._customOffTrackName : this.offTrackName;
			this.offTrack = Button(factory());
			this.offTrack.styleNameList.add(offTrackName);
			this.offTrack.keepDownStateOnRollOut = true;
			this.addChildAt(this.offTrack, 1);
		}
		else if(this.offTrack) //single
		{
			this.offTrack.removeFromParent(true);
			this.offTrack = null;
		}
	}

	/**
	 * @private
	 */
	private function createLabels():Void
	{
		if(this.offTextRenderer)
		{
			this.removeChild(DisplayObject(this.offTextRenderer), true);
			this.offTextRenderer = null;
		}
		if(this.onTextRenderer)
		{
			this.removeChild(DisplayObject(this.onTextRenderer), true);
			this.onTextRenderer = null;
		}

		var index:Int = this.getChildIndex(this.thumb);
		var offLabelFactory:Dynamic = this._offLabelFactory;
		if(offLabelFactory == null)
		{
			offLabelFactory = this._labelFactory;
		}
		if(offLabelFactory == null)
		{
			offLabelFactory = FeathersControl.defaultTextRendererFactory;
		}
		this.offTextRenderer = ITextRenderer(offLabelFactory());
		this.offTextRenderer.styleNameList.add(this.offLabelName);
		this.offTextRenderer.clipRect = new Rectangle();
		this.addChildAt(DisplayObject(this.offTextRenderer), index);

		var onLabelFactory:Dynamic = this._onLabelFactory;
		if(onLabelFactory == null)
		{
			onLabelFactory = this._labelFactory;
		}
		if(onLabelFactory == null)
		{
			onLabelFactory = FeathersControl.defaultTextRendererFactory;
		}
		this.onTextRenderer = ITextRenderer(onLabelFactory());
		this.onTextRenderer.styleNameList.add(this.onLabelName);
		this.onTextRenderer.clipRect = new Rectangle();
		this.addChildAt(DisplayObject(this.onTextRenderer), index);
	}

	/**
	 * @private
	 */
	private function layoutChildren():Void
	{
		this.thumb.validate();
		this.thumb.y = (this.actualHeight - this.thumb.height) / 2;

		var maxLabelWidth:Float = Math.max(0, this.actualWidth - this.thumb.width - this._paddingLeft - this._paddingRight);
		var totalLabelHeight:Float = Math.max(this.onTextRenderer.height, this.offTextRenderer.height);
		var labelHeight:Float;
		if(this._labelAlign == LABEL_ALIGN_MIDDLE)
		{
			labelHeight = totalLabelHeight;
		}
		else //baseline
		{
			labelHeight = Math.max(this.onTextRenderer.baseline, this.offTextRenderer.baseline);
		}

		var clipRect:Rectangle = this.onTextRenderer.clipRect;
		clipRect.width = maxLabelWidth;
		clipRect.height = totalLabelHeight;
		this.onTextRenderer.clipRect = clipRect;

		this.onTextRenderer.y = (this.actualHeight - labelHeight) / 2;

		clipRect = this.offTextRenderer.clipRect;
		clipRect.width = maxLabelWidth;
		clipRect.height = totalLabelHeight;
		this.offTextRenderer.clipRect = clipRect;

		this.offTextRenderer.y = (this.actualHeight - labelHeight) / 2;

		this.layoutTracks();
	}

	/**
	 * @private
	 */
	private function layoutTracks():Void
	{
		var maxLabelWidth:Float = Math.max(0, this.actualWidth - this.thumb.width - this._paddingLeft - this._paddingRight);
		var thumbOffset:Float = this.thumb.x - this._paddingLeft;

		var onScrollOffset:Float = maxLabelWidth - thumbOffset - (maxLabelWidth - this.onTextRenderer.width) / 2;
		var currentClipRect:Rectangle = this.onTextRenderer.clipRect;
		currentClipRect.x = onScrollOffset
		this.onTextRenderer.clipRect = currentClipRect;
		this.onTextRenderer.x = this._paddingLeft - onScrollOffset;

		var offScrollOffset:Float = -thumbOffset - (maxLabelWidth - this.offTextRenderer.width) / 2;
		currentClipRect = this.offTextRenderer.clipRect;
		currentClipRect.x = offScrollOffset
		this.offTextRenderer.clipRect = currentClipRect;
		this.offTextRenderer.x = this.actualWidth - this._paddingRight - maxLabelWidth - offScrollOffset;

		if(this._trackLayoutMode == TRACK_LAYOUT_MODE_ON_OFF)
		{
			this.layoutTrackWithOnOff();
		}
		else
		{
			this.layoutTrackWithSingle();
		}
	}

	/**
	 * @private
	 */
	private function updateSelection():Void
	{
		if(Std.is(this.thumb, IToggle))
		{
			var toggleThumb:IToggle = IToggle(this.thumb);
			if(this._toggleThumbSelection)
			{
				toggleThumb.isSelected = this._isSelected;
			}
			else
			{
				toggleThumb.isSelected = false;
			}
		}
		this.thumb.validate();

		var xPosition:Float = this._paddingLeft;
		if(this._isSelected)
		{
			xPosition = this.actualWidth - this.thumb.width - this._paddingRight;
		}

		//stop the tween, no matter what
		if(this._toggleTween)
		{
			Starling.current.juggler.remove(this._toggleTween);
			this._toggleTween = null;
		}

		if(this._animateSelectionChange)
		{
			this._toggleTween = new Tween(this.thumb, this._toggleDuration, this._toggleEase);
			this._toggleTween.animate("x", xPosition);
			this._toggleTween.onUpdate = selectionTween_onUpdate;
			this._toggleTween.onComplete = selectionTween_onComplete;
			Starling.current.juggler.add(this._toggleTween);
		}
		else
		{
			this.thumb.x = xPosition;
		}
		this._animateSelectionChange = false;
	}

	/**
	 * @private
	 */
	private function refreshOnLabelStyles():Void
	{
		//no need to style the label field if there's no text to display
		if(!this._showLabels || !this._showThumb)
		{
			this.onTextRenderer.visible = false;
			return;
		}

		var properties:PropertyProxy;
		if(!this._isEnabled)
		{
			properties = this._disabledLabelProperties;
		}
		if(!properties && this._onLabelProperties)
		{
			properties = this._onLabelProperties;
		}
		if(!properties)
		{
			properties = this._defaultLabelProperties;
		}

		this.onTextRenderer.text = this._onText;
		if(properties)
		{
			var displayRenderer:DisplayObject = DisplayObject(this.onTextRenderer);
			for (propertyName in properties)
			{
				var propertyValue:Dynamic = properties[propertyName];
				displayRenderer[propertyName] = propertyValue;
			}
		}
		this.onTextRenderer.validate();
		this.onTextRenderer.visible = true;
	}

	/**
	 * @private
	 */
	private function refreshOffLabelStyles():Void
	{
		//no need to style the label field if there's no text to display
		if(!this._showLabels || !this._showThumb)
		{
			this.offTextRenderer.visible = false;
			return;
		}

		var properties:PropertyProxy;
		if(!this._isEnabled)
		{
			properties = this._disabledLabelProperties;
		}
		if(!properties && this._offLabelProperties)
		{
			properties = this._offLabelProperties;
		}
		if(!properties)
		{
			properties = this._defaultLabelProperties;
		}

		this.offTextRenderer.text = this._offText;
		if(properties)
		{
			var displayRenderer:DisplayObject = DisplayObject(this.offTextRenderer);
			for (propertyName in properties)
			{
				var propertyValue:Dynamic = properties[propertyName];
				displayRenderer[propertyName] = propertyValue;
			}
		}
		this.offTextRenderer.validate();
		this.offTextRenderer.visible = true;
	}

	/**
	 * @private
	 */
	private function refreshThumbStyles():Void
	{
		for (propertyName in this._thumbProperties)
		{
			var propertyValue:Dynamic = this._thumbProperties[propertyName];
			this.thumb[propertyName] = propertyValue;
		}
		this.thumb.visible = this._showThumb;
	}

	/**
	 * @private
	 */
	private function refreshOnTrackStyles():Void
	{
		for (propertyName in this._onTrackProperties)
		{
			var propertyValue:Dynamic = this._onTrackProperties[propertyName];
			this.onTrack[propertyName] = propertyValue;
		}
	}

	/**
	 * @private
	 */
	private function refreshOffTrackStyles():Void
	{
		if(!this.offTrack)
		{
			return;
		}
		for (propertyName in this._offTrackProperties)
		{
			var propertyValue:Dynamic = this._offTrackProperties[propertyName];
			this.offTrack[propertyName] = propertyValue;
		}
	}

	/**
	 * @private
	 */
	private function layoutTrackWithOnOff():Void
	{
		this.onTrack.x = 0;
		this.onTrack.y = 0;
		this.onTrack.width = this.thumb.x + this.thumb.width / 2;
		this.onTrack.height = this.actualHeight;

		this.offTrack.x = this.onTrack.width;
		this.offTrack.y = 0;
		this.offTrack.width = this.actualWidth - this.offTrack.x;
		this.offTrack.height = this.actualHeight;

		//final validation to avoid juggler next frame issues
		this.onTrack.validate();
		this.offTrack.validate();
	}

	/**
	 * @private
	 */
	private function layoutTrackWithSingle():Void
	{
		this.onTrack.x = 0;
		this.onTrack.y = 0;
		this.onTrack.width = this.actualWidth;
		this.onTrack.height = this.actualHeight;

		//final validation to avoid juggler next frame issues
		this.onTrack.validate();
	}

	/**
	 * @private
	 */
	private function childProperties_onChange(proxy:PropertyProxy, name:Dynamic):Void
	{
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private function toggleSwitch_removedFromStageHandler(event:Event):Void
	{
		this._touchPointID = -1;
	}

	/**
	 * @private
	 */
	override private function focusInHandler(event:Event):Void
	{
		super.focusInHandler(event);
		this.stage.addEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
		this.stage.addEventListener(KeyboardEvent.KEY_UP, stage_keyUpHandler);
	}

	/**
	 * @private
	 */
	override private function focusOutHandler(event:Event):Void
	{
		super.focusOutHandler(event);
		this.stage.removeEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
		this.stage.removeEventListener(KeyboardEvent.KEY_UP, stage_keyUpHandler);
	}

	/**
	 * @private
	 */
	private function toggleSwitch_touchHandler(event:TouchEvent):Void
	{
		if(this._ignoreTapHandler)
		{
			this._ignoreTapHandler = false;
			return;
		}
		if(!this._isEnabled)
		{
			this._touchPointID = -1;
			return;
		}

		var touch:Touch = event.getTouch(this, TouchPhase.ENDED);
		if(!touch)
		{
			return;
		}
		this._touchPointID = -1;
		touch.getLocation(this.stage, HELPER_POINT);
		var isInBounds:Bool = this.contains(this.stage.hitTest(HELPER_POINT, true));
		if(isInBounds)
		{
			this.setSelectionWithAnimation(!this._isSelected);
		}
	}

	/**
	 * @private
	 */
	private function thumb_touchHandler(event:TouchEvent):Void
	{
		if(!this._isEnabled)
		{
			this._touchPointID = -1;
			return;
		}

		if(this._touchPointID >= 0)
		{
			var touch:Touch = event.getTouch(this.thumb, null, this._touchPointID);
			if(!touch)
			{
				return;
			}
			touch.getLocation(this, HELPER_POINT);
			var trackScrollableWidth:Float = this.actualWidth - this._paddingLeft - this._paddingRight - this.thumb.width;
			if(touch.phase == TouchPhase.MOVED)
			{
				var xOffset:Float = HELPER_POINT.x - this._touchStartX;
				var xPosition:Float = Math.min(Math.max(this._paddingLeft, this._thumbStartX + xOffset), this._paddingLeft + trackScrollableWidth);
				this.thumb.x = xPosition;
				this.layoutTracks();
			}
			else if(touch.phase == TouchPhase.ENDED)
			{
				var pixelsMoved:Float = Math.abs(HELPER_POINT.x - this._touchStartX);
				var inchesMoved:Float = pixelsMoved / DeviceCapabilities.dpi;
				if(inchesMoved > MINIMUM_DRAG_DISTANCE || (SystemUtil.isDesktop && pixelsMoved >= 1))
				{
					this._touchPointID = -1;
					this._ignoreTapHandler = true;
					this.setSelectionWithAnimation(this.thumb.x > (this._paddingLeft + trackScrollableWidth / 2));
					//we still need to invalidate, even if there's no change
					//because the thumb may be in the middle!
					this.invalidate(FeathersControl.INVALIDATION_FLAG_SELECTED);
				}
			}
		}
		else
		{
			touch = event.getTouch(this.thumb, TouchPhase.BEGAN);
			if(!touch)
			{
				return;
			}
			touch.getLocation(this, HELPER_POINT);
			this._touchPointID = touch.id;
			this._thumbStartX = this.thumb.x;
			this._touchStartX = HELPER_POINT.x;
		}
	}

	/**
	 * @private
	 */
	private function stage_keyDownHandler(event:KeyboardEvent):Void
	{
		if(event.keyCode == Keyboard.ESCAPE)
		{
			this._touchPointID = -1;
		}
		if(this._touchPointID >= 0 || event.keyCode != Keyboard.SPACE)
		{
			return;
		}
		this._touchPointID = Int.MAX_VALUE;
	}

	/**
	 * @private
	 */
	private function stage_keyUpHandler(event:KeyboardEvent):Void
	{
		if(this._touchPointID != Int.MAX_VALUE || event.keyCode != Keyboard.SPACE)
		{
			return;
		}
		this._touchPointID = -1;
		this.setSelectionWithAnimation(!this._isSelected);
	}

	/**
	 * @private
	 */
	private function selectionTween_onUpdate():Void
	{
		this.layoutTracks();
	}

	/**
	 * @private
	 */
	private function selectionTween_onComplete():Void
	{
		this._toggleTween = null;
	}
}