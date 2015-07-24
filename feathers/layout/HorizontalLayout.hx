/*
Feathers
Copyright 2012-2014 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.layout;
import feathers.core.IFeathersControl;
import feathers.core.IValidating;
import feathers.utils.type.SafeCast.safe_cast;

import openfl.errors.IllegalOperationError;
import openfl.geom.Point;

import starling.display.DisplayObject;
import starling.events.Event;
import starling.events.EventDispatcher;

/**
 * Dispatched when a property of the layout changes, indicating that a
 * redraw is probably needed.
 *
 * @eventType starling.events.Event.CHANGE
 */
//[Event(name="change",type="starling.events.Event")]

/**
 * Positions items from left to right in a single row.
 *
 * @see http://wiki.starling-framework.org/feathers/horizontal-layout
 */
class HorizontalLayout extends EventDispatcher implements IVariableVirtualLayout implements ITrimmedVirtualLayout
{
	/**
	 * The items will be aligned to the top of the bounds.
	 *
	 * @see #verticalAlign
	 */
	inline public static var VERTICAL_ALIGN_TOP:String = "top";

	/**
	 * The items will be aligned to the middle of the bounds.
	 *
	 * @see #verticalAlign
	 */
	inline public static var VERTICAL_ALIGN_MIDDLE:String = "middle";

	/**
	 * The items will be aligned to the bottom of the bounds.
	 *
	 * @see #verticalAlign
	 */
	inline public static var VERTICAL_ALIGN_BOTTOM:String = "bottom";

	/**
	 * The items will fill the height of the bounds.
	 *
	 * @see #verticalAlign
	 */
	inline public static var VERTICAL_ALIGN_JUSTIFY:String = "justify";

	/**
	 * If the total item width is smaller than the width of the bounds, the
	 * items will be aligned to the left.
	 *
	 * @see #horizontalAlign
	 */
	inline public static var HORIZONTAL_ALIGN_LEFT:String = "left";

	/**
	 * If the total item width is smaller than the width of the bounds, the
	 * items will be aligned to the center.
	 *
	 * @see #horizontalAlign
	 */
	inline public static var HORIZONTAL_ALIGN_CENTER:String = "center";

	/**
	 * If the total item width is smaller than the width of the bounds, the
	 * items will be aligned to the right.
	 *
	 * @see #horizontalAlign
	 */
	inline public static var HORIZONTAL_ALIGN_RIGHT:String = "right";

	/**
	 * Constructor.
	 */
	public function new()
	{
		super();
	}

	/**
	 * @private
	 */
	private var _widthCache:Array<Float> = [];

	/**
	 * @private
	 */
	private var _discoveredItemsCache:Array<DisplayObject> = new Array();

	/**
	 * @private
	 */
	private var _gap:Float = 0;

	/**
	 * The space, in pixels, between items.
	 *
	 * @default 0
	 */
	public var gap(get, set):Float;
	public function get_gap():Float
	{
		return this._gap;
	}

	/**
	 * @private
	 */
	public function set_gap(value:Float):Float
	{
		if(this._gap == value)
		{
			return get_gap();
		}
		this._gap = value;
		this.dispatchEventWith(Event.CHANGE);
		return get_gap();
	}

	/**
	 * @private
	 */
	private var _firstGap:Float = Math.NaN;

	/**
	 * The space, in pixels, between the first and second items. If the
	 * value of <code>firstGap</code> is <code>NaN</code>, the value of the
	 * <code>gap</code> property will be used instead.
	 *
	 * @default NaN
	 */
	public var firstGap(get, set):Float;
	public function get_firstGap():Float
	{
		return this._firstGap;
	}

	/**
	 * @private
	 */
	public function set_firstGap(value:Float):Float
	{
		if(this._firstGap == value)
		{
			return get_firstGap();
		}
		this._firstGap = value;
		this.dispatchEventWith(Event.CHANGE);
		return get_firstGap();
	}

	/**
	 * @private
	 */
	private var _lastGap:Float = Math.NaN;

	/**
	 * The space, in pixels, between the last and second to last items. If
	 * the value of <code>lastGap</code> is <code>NaN</code>, the value of
	 * the <code>gap</code> property will be used instead.
	 *
	 * @default NaN
	 */
	public var lastGap(get, set):Float;
	public function get_lastGap():Float
	{
		return this._lastGap;
	}

	/**
	 * @private
	 */
	public function set_lastGap(value:Float):Float
	{
		if(this._lastGap == value)
		{
			return get_lastGap();
		}
		this._lastGap = value;
		this.dispatchEventWith(Event.CHANGE);
		return get_lastGap();
	}

	/**
	 * Quickly sets all padding properties to the same value. The
	 * <code>padding</code> getter always returns the value of
	 * <code>paddingTop</code>, but the other padding values may be
	 * different.
	 *
	 * @default 0
	 *
	 * @see #paddingTop
	 * @see #paddingRight
	 * @see #paddingBottom
	 * @see #paddingLeft
	 */
	public var padding(get, set):Float;
	public function get_padding():Float
	{
		return this._paddingTop;
	}

	/**
	 * @private
	 */
	public function set_padding(value:Float):Float
	{
		this.paddingTop = value;
		this.paddingRight = value;
		this.paddingBottom = value;
		this.paddingLeft = value;
		return get_padding();
	}

	/**
	 * @private
	 */
	private var _paddingTop:Float = 0;

	/**
	 * The minimum space, in pixels, above the items.
	 *
	 * @default 0
	 */
	public var paddingTop(get, set):Float;
	public function get_paddingTop():Float
	{
		return this._paddingTop;
	}

	/**
	 * @private
	 */
	public function set_paddingTop(value:Float):Float
	{
		if(this._paddingTop == value)
		{
			return get_paddingTop();
		}
		this._paddingTop = value;
		this.dispatchEventWith(Event.CHANGE);
		return get_paddingTop();
	}

	/**
	 * @private
	 */
	private var _paddingRight:Float = 0;

	/**
	 * The space, in pixels, that appears to the right, after the last item.
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
			return get_paddingRight();
		}
		this._paddingRight = value;
		this.dispatchEventWith(Event.CHANGE);
		return get_paddingRight();
	}

	/**
	 * @private
	 */
	private var _paddingBottom:Float = 0;

	/**
	 * The minimum space, in pixels, above the items.
	 *
	 * @default 0
	 */
	public var paddingBottom(get, set):Float;
	public function get_paddingBottom():Float
	{
		return this._paddingBottom;
	}

	/**
	 * @private
	 */
	public function set_paddingBottom(value:Float):Float
	{
		if(this._paddingBottom == value)
		{
			return get_paddingBottom();
		}
		this._paddingBottom = value;
		this.dispatchEventWith(Event.CHANGE);
		return get_paddingBottom();
	}

	/**
	 * @private
	 */
	private var _paddingLeft:Float = 0;

	/**
	 * The space, in pixels, that appears to the left, before the first
	 * item.
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
			return get_paddingLeft();
		}
		this._paddingLeft = value;
		this.dispatchEventWith(Event.CHANGE);
		return get_paddingLeft();
	}


	/**
	 * @private
	 */
	private var _verticalAlign:String = VERTICAL_ALIGN_TOP;

	//[Inspectable(type="String",enumeration="top,middle,bottom,justify")]
	/**
	 * The alignment of the items vertically, on the y-axis.
	 *
	 * @default HorizontalLayout.VERTICAL_ALIGN_TOP
	 *
	 * @see #VERTICAL_ALIGN_TOP
	 * @see #VERTICAL_ALIGN_MIDDLE
	 * @see #VERTICAL_ALIGN_BOTTOM
	 * @see #VERTICAL_ALIGN_JUSTIFY
	 */
	public var verticalAlign(get, set):String;
	public function get_verticalAlign():String
	{
		return this._verticalAlign;
	}

	/**
	 * @private
	 */
	public function set_verticalAlign(value:String):String
	{
		if(this._verticalAlign == value)
		{
			return get_verticalAlign();
		}
		this._verticalAlign = value;
		this.dispatchEventWith(Event.CHANGE);
		return get_verticalAlign();
	}

	/**
	 * @private
	 */
	private var _horizontalAlign:String = HORIZONTAL_ALIGN_LEFT;

	//[Inspectable(type="String",enumeration="left,center,right")]
	/**
	 * If the total item width is less than the bounds, the positions of
	 * the items can be aligned horizontally.
	 *
	 * @default HorizontalLayout.HORIZONTAL_ALIGN_LEFT
	 *
	 * @see #HORIZONTAL_ALIGN_LEFT
	 * @see #HORIZONTAL_ALIGN_CENTER
	 * @see #HORIZONTAL_ALIGN_RIGHT
	 */
	public var horizontalAlign(get, set):String;
	public function get_horizontalAlign():String
	{
		return this._horizontalAlign;
	}

	/**
	 * @private
	 */
	public function set_horizontalAlign(value:String):String
	{
		if(this._horizontalAlign == value)
		{
			return get_horizontalAlign();
		}
		this._horizontalAlign = value;
		this.dispatchEventWith(Event.CHANGE);
		return get_horizontalAlign();
	}

	/**
	 * @private
	 */
	private var _useVirtualLayout:Bool = true;

	/**
	 * @inheritDoc
	 *
	 * @default true
	 */
	public var useVirtualLayout(get, set):Bool;
	public function get_useVirtualLayout():Bool
	{
		return this._useVirtualLayout;
	}

	/**
	 * @private
	 */
	public function set_useVirtualLayout(value:Bool):Bool
	{
		if(this._useVirtualLayout == value)
		{
			return get_useVirtualLayout();
		}
		this._useVirtualLayout = value;
		this.dispatchEventWith(Event.CHANGE);
		return get_useVirtualLayout();
	}

	/**
	 * @private
	 */
	private var _hasVariableItemDimensions:Bool = false;

	/**
	 * When the layout is virtualized, and this value is true, the items may
	 * have variable height values. If false, the items will all share the
	 * same height value with the typical item.
	 *
	 * @default false
	 */
	public var hasVariableItemDimensions(get, set):Bool;
	public function get_hasVariableItemDimensions():Bool
	{
		return this._hasVariableItemDimensions;
	}

	/**
	 * @private
	 */
	public function set_hasVariableItemDimensions(value:Bool):Bool
	{
		if(this._hasVariableItemDimensions == value)
		{
			return get_hasVariableItemDimensions();
		}
		this._hasVariableItemDimensions = value;
		this.dispatchEventWith(Event.CHANGE);
		return get_hasVariableItemDimensions();
	}

	/**
	 * @private
	 */
	private var _distributeWidths:Bool = false;

	/**
	 * Distributes the width of the view port equally to each item. If the
	 * view port width needs to be measured, the largest item's width will
	 * be used for all items, subject to any specified minimum and maximum
	 * width values.
	 *
	 * @default false
	 */
	public var distributeWidths(get, set):Bool;
	public function get_distributeWidths():Bool
	{
		return this._distributeWidths;
	}

	/**
	 * @private
	 */
	public function set_distributeWidths(value:Bool):Bool
	{
		if(this._distributeWidths == value)
		{
			return get_distributeWidths();
		}
		this._distributeWidths = value;
		this.dispatchEventWith(Event.CHANGE);
		return get_distributeWidths();
	}

	/**
	 * @private
	 */
	private var _manageVisibility:Bool = false;

	/**
	 * Determines if items will be set invisible if they are outside the
	 * view port. If <code>true</code>, you will not be able to manually
	 * change the <code>visible</code> property of any items in the layout.
	 *
	 * <p><strong>DEPRECATION WARNING:</strong> This property is deprecated
	 * starting with Feathers 2.0. It will be removed in a future version of
	 * Feathers according to the standard
	 * <a href="http://wiki.starling-framework.org/feathers/deprecation-policy">Feathers deprecation policy</a>.
	 * Originally, the <code>manageVisibility</code> property could be used
	 * to improve performance of non-virtual layouts by hiding items that
	 * were outside the view port. However, other performance improvements
	 * have made it so that setting <code>manageVisibility</code> can now
	 * sometimes hurt performance instead of improving it.</p>
	 *
	 * @default false
	 */
	public var manageVisibility(get, set):Bool;
	public function get_manageVisibility():Bool
	{
		return this._manageVisibility;
	}

	/**
	 * @private
	 */
	public function set_manageVisibility(value:Bool):Bool
	{
		if(this._manageVisibility == value)
		{
			return get_manageVisibility();
		}
		this._manageVisibility = value;
		this.dispatchEventWith(Event.CHANGE);
		return get_manageVisibility();
	}

	/**
	 * @private
	 */
	private var _beforeVirtualizedItemCount:Int = 0;

	/**
	 * @inheritDoc
	 */
	public var beforeVirtualizedItemCount(get, set):Int;
	public function get_beforeVirtualizedItemCount():Int
	{
		return this._beforeVirtualizedItemCount;
	}

	/**
	 * @private
	 */
	public function set_beforeVirtualizedItemCount(value:Int):Int
	{
		if(this._beforeVirtualizedItemCount == value)
		{
			return get_beforeVirtualizedItemCount();
		}
		this._beforeVirtualizedItemCount = value;
		this.dispatchEventWith(Event.CHANGE);
		return get_beforeVirtualizedItemCount();
	}

	/**
	 * @private
	 */
	private var _afterVirtualizedItemCount:Int = 0;

	/**
	 * @inheritDoc
	 */
	public var afterVirtualizedItemCount(get, set):Int;
	public function get_afterVirtualizedItemCount():Int
	{
		return this._afterVirtualizedItemCount;
	}

	/**
	 * @private
	 */
	public function set_afterVirtualizedItemCount(value:Int):Int
	{
		if(this._afterVirtualizedItemCount == value)
		{
			return get_afterVirtualizedItemCount();
		}
		this._afterVirtualizedItemCount = value;
		this.dispatchEventWith(Event.CHANGE);
		return get_afterVirtualizedItemCount();
	}

	/**
	 * @private
	 */
	private var _typicalItem:DisplayObject;

	/**
	 * @inheritDoc
	 *
	 * @see #resetTypicalItemDimensionsOnMeasure
	 * @see #typicalItemWidth
	 * @see #typicalItemHeight
	 */
	public var typicalItem(get, set):DisplayObject;
	public function get_typicalItem():DisplayObject
	{
		return this._typicalItem;
	}

	/**
	 * @private
	 */
	public function set_typicalItem(value:DisplayObject):DisplayObject
	{
		if(this._typicalItem == value)
		{
			return get_typicalItem();
		}
		this._typicalItem = value;
		this.dispatchEventWith(Event.CHANGE);
		return get_typicalItem();
	}

	/**
	 * @private
	 */
	private var _resetTypicalItemDimensionsOnMeasure:Bool = false;

	/**
	 * If set to <code>true</code>, the width and height of the
	 * <code>typicalItem</code> will be reset to <code>typicalItemWidth</code>
	 * and <code>typicalItemHeight</code>, respectively, whenever the
	 * typical item needs to be measured. The measured dimensions of the
	 * typical item are used to fill in the blanks of a virtualized layout
	 * for virtual items that don't have their own display objects to
	 * measure yet.
	 *
	 * @default false
	 *
	 * @see #typicalItemWidth
	 * @see #typicalItemHeight
	 * @see #typicalItem
	 */
	public var resetTypicalItemDimensionsOnMeasure(get, set):Bool;
	public function get_resetTypicalItemDimensionsOnMeasure():Bool
	{
		return this._resetTypicalItemDimensionsOnMeasure;
	}

	/**
	 * @private
	 */
	public function set_resetTypicalItemDimensionsOnMeasure(value:Bool):Bool
	{
		if(this._resetTypicalItemDimensionsOnMeasure == value)
		{
			return get_resetTypicalItemDimensionsOnMeasure();
		}
		this._resetTypicalItemDimensionsOnMeasure = value;
		this.dispatchEventWith(Event.CHANGE);
		return get_resetTypicalItemDimensionsOnMeasure();
	}

	/**
	 * @private
	 */
	private var _typicalItemWidth:Float = Math.NaN;

	/**
	 * Used to reset the width, in pixels, of the <code>typicalItem</code>
	 * for measurement. The measured dimensions of the typical item are used
	 * to fill in the blanks of a virtualized layout for virtual items that
	 * don't have their own display objects to measure yet.
	 *
	 * <p>This value is only used when <code>resetTypicalItemDimensionsOnMeasure</code>
	 * is set to <code>true</code>. If <code>resetTypicalItemDimensionsOnMeasure</code>
	 * is set to <code>false</code>, this value will be ignored and the
	 * <code>typicalItem</code> dimensions will not be reset before
	 * measurement.</p>
	 *
	 * <p>If <code>typicalItemWidth</code> is set to <code>NaN</code>, the
	 * typical item will auto-size itself to its preferred width. If you
	 * pass a valid <code>Float</code> value, the typical item's width will
	 * be set to a fixed size. May be used in combination with
	 * <code>typicalItemHeight</code>.</p>
	 *
	 * @default NaN
	 *
	 * @see #resetTypicalItemDimensionsOnMeasure
	 * @see #typicalItemHeight
	 * @see #typicalItem
	 */
	public var typicalItemWidth(get, set):Float;
	public function get_typicalItemWidth():Float
	{
		return this._typicalItemWidth;
	}

	/**
	 * @private
	 */
	public function set_typicalItemWidth(value:Float):Float
	{
		if(this._typicalItemWidth == value)
		{
			return get_typicalItemWidth();
		}
		this._typicalItemWidth = value;
		this.dispatchEventWith(Event.CHANGE);
		return get_typicalItemWidth();
	}

	/**
	 * @private
	 */
	private var _typicalItemHeight:Float = Math.NaN;

	/**
	 * Used to reset the height, in pixels, of the <code>typicalItem</code>
	 * for measurement. The measured dimensions of the typical item are used
	 * to fill in the blanks of a virtualized layout for virtual items that
	 * don't have their own display objects to measure yet.
	 *
	 * <p>This value is only used when <code>resetTypicalItemDimensionsOnMeasure</code>
	 * is set to <code>true</code>. If <code>resetTypicalItemDimensionsOnMeasure</code>
	 * is set to <code>false</code>, this value will be ignored and the
	 * <code>typicalItem</code> dimensions will not be reset before
	 * measurement.</p>
	 *
	 * <p>If <code>typicalItemHeight</code> is set to <code>NaN</code>, the
	 * typical item will auto-size itself to its preferred height. If you
	 * pass a valid <code>Float</code> value, the typical item's height will
	 * be set to a fixed size. May be used in combination with
	 * <code>typicalItemWidth</code>.</p>
	 *
	 * @default NaN
	 *
	 * @see #resetTypicalItemDimensionsOnMeasure
	 * @see #typicalItemWidth
	 * @see #typicalItem
	 */
	public var typicalItemHeight(get, set):Float;
	public function get_typicalItemHeight():Float
	{
		return this._typicalItemHeight;
	}

	/**
	 * @private
	 */
	public function set_typicalItemHeight(value:Float):Float
	{
		if(this._typicalItemHeight == value)
		{
			return get_typicalItemHeight();
		}
		this._typicalItemHeight = value;
		this.dispatchEventWith(Event.CHANGE);
		return get_typicalItemHeight();
	}

	/**
	 * @private
	 */
	private var _scrollPositionHorizontalAlign:String = HORIZONTAL_ALIGN_CENTER;

	//[Inspectable(type="String",enumeration="left,center,right")]
	/**
	 * When the scroll position is calculated for an item, an attempt will
	 * be made to align the item to this position.
	 *
	 * @default HorizontalLayout.HORIZONTAL_ALIGN_CENTER
	 *
	 * @see #HORIZONTAL_ALIGN_LEFT
	 * @see #HORIZONTAL_ALIGN_CENTER
	 * @see #HORIZONTAL_ALIGN_RIGHT
	 */
	public var scrollPositionHorizontalAlign(get, set):String;
	public function get_scrollPositionHorizontalAlign():String
	{
		return this._scrollPositionHorizontalAlign;
	}

	/**
	 * @private
	 */
	public function set_scrollPositionHorizontalAlign(value:String):String
	{
		this._scrollPositionHorizontalAlign = value;
		return get_scrollPositionHorizontalAlign();
	}

	/**
	 * @inheritDoc
	 */
	public var requiresLayoutOnScroll(get, never):Bool;
	public function get_requiresLayoutOnScroll():Bool
	{
		return this._manageVisibility || this._useVirtualLayout;
	}

	/**
	 * @inheritDoc
	 */
	public function layout(items:Array<DisplayObject>, viewPortBounds:ViewPortBounds = null, result:LayoutBoundsResult = null):LayoutBoundsResult
	{
		var scrollX:Float = viewPortBounds != null ? viewPortBounds.scrollX : 0;
		var scrollY:Float = viewPortBounds != null ? viewPortBounds.scrollY : 0;
		var boundsX:Float = viewPortBounds != null ? viewPortBounds.x : 0;
		var boundsY:Float = viewPortBounds != null ? viewPortBounds.y : 0;
		var minWidth:Float = viewPortBounds != null ? viewPortBounds.minWidth : 0;
		var minHeight:Float = viewPortBounds != null ? viewPortBounds.minHeight : 0;
		var maxWidth:Float = viewPortBounds != null ? viewPortBounds.maxWidth : Math.POSITIVE_INFINITY;
		var maxHeight:Float = viewPortBounds != null ? viewPortBounds.maxHeight : Math.POSITIVE_INFINITY;
		var explicitWidth:Float = viewPortBounds != null ? viewPortBounds.explicitWidth : Math.NaN;
		var explicitHeight:Float = viewPortBounds != null ? viewPortBounds.explicitHeight : Math.NaN;
		
		var calculatedTypicalItemWidth:Float = Math.NaN;
		var calculatedTypicalItemHeight:Float = Math.NaN;

		if(this._useVirtualLayout)
		{
			this.prepareTypicalItem(explicitHeight - this._paddingTop - this._paddingBottom);
			calculatedTypicalItemWidth = this._typicalItem != null ? this._typicalItem.width : 0;
			calculatedTypicalItemHeight = this._typicalItem != null ? this._typicalItem.height : 0;
		}

		if(!this._useVirtualLayout || this._hasVariableItemDimensions || this._distributeWidths ||
			this._verticalAlign != VERTICAL_ALIGN_JUSTIFY ||
			explicitHeight != explicitHeight) //isNaN
		{
			this.validateItems(items, explicitHeight - this._paddingTop - this._paddingBottom, explicitWidth);
		}

		if(!this._useVirtualLayout)
		{
			this.applyPercentWidths(items, explicitWidth, minWidth, maxWidth);
		}

		var distributedWidth:Float = Math.NaN;
		if(this._distributeWidths)
		{
			distributedWidth = this.calculateDistributedWidth(items, explicitWidth, minWidth, maxWidth);
		}
		var hasDistributedWidth:Bool = distributedWidth == distributedWidth; //!isNaN

		this._discoveredItemsCache.splice(0, this._discoveredItemsCache.length);
		var hasFirstGap:Bool = this._firstGap == this._firstGap; //!isNaN
		var hasLastGap:Bool = this._lastGap == this._lastGap; //!isNaN
		var maxItemHeight:Float = this._useVirtualLayout ? calculatedTypicalItemHeight : 0;
		var positionX:Float = boundsX + this._paddingLeft;
		var itemCount:Int = items.length;
		var totalItemCount:Int = itemCount;
		if(this._useVirtualLayout && !this._hasVariableItemDimensions)
		{
			totalItemCount += this._beforeVirtualizedItemCount + this._afterVirtualizedItemCount;
			positionX += (this._beforeVirtualizedItemCount * (calculatedTypicalItemWidth + this._gap));
			if(hasFirstGap && this._beforeVirtualizedItemCount > 0)
			{
				positionX = positionX - this._gap + this._firstGap;
			}
		}
		var secondToLastIndex:Int = totalItemCount - 2;
		var discoveredItemsCacheLastIndex:Int = 0;
		var cachedWidth:Float = Math.NaN;
		var item:DisplayObject;
		var itemHeight:Float;
		//for(var i:Int = 0; i < itemCount; i++)
		for(i in 0 ... itemCount)
		{
			item = items[i];
			var iNormalized:Int = i + this._beforeVirtualizedItemCount;
			var gap:Float = this._gap;
			if(hasFirstGap && iNormalized == 0)
			{
				gap = this._firstGap;
			}
			else if(hasLastGap && iNormalized > 0 && iNormalized == secondToLastIndex)
			{
				gap = this._lastGap;
			}
			if(this._useVirtualLayout && this._hasVariableItemDimensions)
			{
				cachedWidth = this._widthCache[iNormalized];
			}
			if(this._useVirtualLayout && item == null)
			{
				if(!this._hasVariableItemDimensions ||
					cachedWidth != cachedWidth) //isNaN
				{
					positionX += calculatedTypicalItemWidth + gap;
				}
				else
				{
					positionX += cachedWidth + gap;
				}
			}
			else
			{
				if(Std.is(item, ILayoutDisplayObject) && !cast(item, ILayoutDisplayObject).includeInLayout)
				{
					continue;
				}
				item.x = item.pivotX + positionX;
				var itemWidth:Float;
				if(hasDistributedWidth)
				{
					item.width = itemWidth = distributedWidth;
				}
				else
				{
					itemWidth = item.width;
				}
				itemHeight = item.height;
				if(this._useVirtualLayout)
				{
					if(this._hasVariableItemDimensions)
					{
						if(itemWidth != cachedWidth)
						{
							this._widthCache[iNormalized] = itemWidth;
							this.dispatchEventWith(Event.CHANGE);
						}
					}
					else if(calculatedTypicalItemWidth >= 0)
					{
						item.width = itemWidth = calculatedTypicalItemWidth;
					}
				}
				positionX += itemWidth + gap;
				if(itemHeight > maxItemHeight)
				{
					maxItemHeight = itemHeight;
				}
				if(this._useVirtualLayout)
				{
					this._discoveredItemsCache[discoveredItemsCacheLastIndex] = item;
					discoveredItemsCacheLastIndex++;
				}
			}
		}
		if(this._useVirtualLayout && !this._hasVariableItemDimensions)
		{
			positionX += (this._afterVirtualizedItemCount * (calculatedTypicalItemWidth + this._gap));
			if(hasLastGap && this._afterVirtualizedItemCount > 0)
			{
				positionX = positionX - this._gap + this._lastGap;
			}
		}

		var discoveredItems:Array<DisplayObject> = this._useVirtualLayout ? this._discoveredItemsCache : items;
		var discoveredItemCount:Int = discoveredItems.length;

		var totalHeight:Float = maxItemHeight + this._paddingTop + this._paddingBottom;
		var availableHeight:Float = explicitHeight;
		if(availableHeight != availableHeight) //isNaN
		{
			availableHeight = totalHeight;
			if(availableHeight < minHeight)
			{
				availableHeight = minHeight;
			}
			else if(availableHeight > maxHeight)
			{
				availableHeight = maxHeight;
			}
		}
		var totalWidth:Float = positionX - this._gap + this._paddingRight - boundsX;
		var availableWidth:Float = explicitWidth;
		if(availableWidth != availableWidth) //isNaN
		{
			availableWidth = totalWidth;
			if(availableWidth < minWidth)
			{
				availableWidth = minWidth;
			}
			else if(availableWidth > maxWidth)
			{
				availableWidth = maxWidth;
			}
		}

		if(totalWidth < availableWidth)
		{
			var horizontalAlignOffsetX:Float = 0;
			if(this._horizontalAlign == HORIZONTAL_ALIGN_RIGHT)
			{
				horizontalAlignOffsetX = availableWidth - totalWidth;
			}
			else if(this._horizontalAlign == HORIZONTAL_ALIGN_CENTER)
			{
				horizontalAlignOffsetX = Math.round((availableWidth - totalWidth) / 2);
			}
			if(horizontalAlignOffsetX != 0)
			{
				//for(i = 0; i < discoveredItemCount; i++)
				for(i in 0 ... discoveredItemCount)
				{
					item = discoveredItems[i];
					if(Std.is(item, ILayoutDisplayObject) && !cast(item, ILayoutDisplayObject).includeInLayout)
					{
						continue;
					}
					item.x += horizontalAlignOffsetX;
				}
			}
		}

		//for(i = 0; i < discoveredItemCount; i++)
		for(i in 0 ... discoveredItemCount)
		{
			item = discoveredItems[i];
			var layoutItem:ILayoutDisplayObject = safe_cast(item, ILayoutDisplayObject);
			if(layoutItem != null && !layoutItem.includeInLayout)
			{
				continue;
			}
			if(this._verticalAlign == VERTICAL_ALIGN_JUSTIFY)
			{
				item.y = item.pivotY + boundsY + this._paddingTop;
				item.height = availableHeight - this._paddingTop - this._paddingBottom;
			}
			else
			{
				if(layoutItem != null)
				{
					var layoutData:HorizontalLayoutData = safe_cast(layoutItem.layoutData, HorizontalLayoutData);
					if(layoutData != null)
					{
						var percentHeight:Float = layoutData.percentHeight;
						if(percentHeight == percentHeight) //!isNaN
						{
							if(percentHeight < 0)
							{
								percentHeight = 0;
							}
							if(percentHeight > 100)
							{
								percentHeight = 100;
							}
							itemHeight = percentHeight * (availableHeight - this._paddingTop - this._paddingBottom) / 100;
							if(Std.is(item, IFeathersControl))
							{
								var feathersItem:IFeathersControl = cast item;
								var itemMinHeight:Float = feathersItem.minHeight;
								if(itemHeight < itemMinHeight)
								{
									itemHeight = itemMinHeight;
								}
								else
								{
									var itemMaxHeight:Float = feathersItem.maxHeight;
									if(itemHeight > itemMaxHeight)
									{
										itemHeight = itemMaxHeight;
									}
								}
							}
							item.height = itemHeight;
						}
					}
				}
				switch(this._verticalAlign)
				{
					case VERTICAL_ALIGN_BOTTOM:
					{
						item.y = item.pivotY + boundsY + availableHeight - this._paddingBottom - item.height;
						//break;
					}
					case VERTICAL_ALIGN_MIDDLE:
					{
						item.y = item.pivotY + boundsY + this._paddingTop + Math.round((availableHeight - this._paddingTop - this._paddingBottom - item.height) / 2);
						//break;
					}
					default: //top
					{
						item.y = item.pivotY + boundsY + this._paddingTop;
					}
				}
			}
			if(this.manageVisibility)
			{
				item.visible = ((item.x - item.pivotX + item.width) >= (boundsX + scrollX)) && ((item.x - item.pivotX) < (scrollX + availableWidth));
			}
		}
		this._discoveredItemsCache.splice(0, this._discoveredItemsCache.length);

		if(result == null)
		{
			result = new LayoutBoundsResult();
		}
		result.contentWidth = totalWidth;
		result.contentHeight = this._verticalAlign == VERTICAL_ALIGN_JUSTIFY ? availableHeight : totalHeight;
		result.viewPortWidth = availableWidth;
		result.viewPortHeight = availableHeight;
		return result;
	}

	/**
	 * @inheritDoc
	 */
	public function measureViewPort(itemCount:Int, viewPortBounds:ViewPortBounds = null, result:Point = null):Point
	{
		if(result == null)
		{
			result = new Point();
		}
		if(!this._useVirtualLayout)
		{
			throw new IllegalOperationError("measureViewPort() may be called only if useVirtualLayout is true.");
		}

		var explicitWidth:Float = viewPortBounds != null ? viewPortBounds.explicitWidth : Math.NaN;
		var explicitHeight:Float = viewPortBounds != null ? viewPortBounds.explicitHeight : Math.NaN;
		var needsWidth:Bool = explicitWidth != explicitWidth; //isNaN
		var needsHeight:Bool = explicitHeight != explicitHeight; //isNaN
		if(!needsWidth && !needsHeight)
		{
			result.x = explicitWidth;
			result.y = explicitHeight;
			return result;
		}
		var minWidth:Float = viewPortBounds != null ? viewPortBounds.minWidth : 0;
		var minHeight:Float = viewPortBounds != null ? viewPortBounds.minHeight : 0;
		var maxWidth:Float = viewPortBounds != null ? viewPortBounds.maxWidth : Math.POSITIVE_INFINITY;
		var maxHeight:Float = viewPortBounds != null ? viewPortBounds.maxHeight : Math.POSITIVE_INFINITY;

		this.prepareTypicalItem(explicitHeight - this._paddingTop - this._paddingBottom);
		var calculatedTypicalItemWidth:Float = this._typicalItem != null ? this._typicalItem.width : 0;
		var calculatedTypicalItemHeight:Float = this._typicalItem != null ? this._typicalItem.height : 0;

		var hasFirstGap:Bool = this._firstGap == this._firstGap; //!isNaN
		var hasLastGap:Bool = this._lastGap == this._lastGap; //!isNaN
		var positionX:Float;
		var maxItemHeight:Float = 0;
		if(this._distributeWidths)
		{
			positionX = (calculatedTypicalItemWidth + this._gap) * itemCount;
		}
		else
		{
			positionX = 0;
			maxItemHeight = calculatedTypicalItemHeight;
			if(!this._hasVariableItemDimensions)
			{
				positionX += ((calculatedTypicalItemWidth + this._gap) * itemCount);
			}
			else
			{
				//for(var i:Int = 0; i < itemCount; i++)
				for(i in 0 ... itemCount)
				{
					var cachedWidth:Float = this._widthCache[i];
					if(cachedWidth != cachedWidth) //isNaN
					{
						positionX += calculatedTypicalItemWidth + this._gap;
					}
					else
					{
						positionX += cachedWidth + this._gap;
					}
				}
			}
		}
		positionX -= this._gap;
		if(hasFirstGap && itemCount > 1)
		{
			positionX = positionX - this._gap + this._firstGap;
		}
		if(hasLastGap && itemCount > 2)
		{
			positionX = positionX - this._gap + this._lastGap;
		}

		if(needsWidth)
		{
			var resultWidth:Float = positionX + this._paddingLeft + this._paddingRight;
			if(resultWidth < minWidth)
			{
				resultWidth = minWidth;
			}
			else if(resultWidth > maxWidth)
			{
				resultWidth = maxWidth;
			}
			result.x = resultWidth;
		}
		else
		{
			result.x = explicitWidth;
		}

		if(needsHeight)
		{
			var resultHeight:Float = maxItemHeight + this._paddingTop + this._paddingBottom;
			if(resultHeight < minHeight)
			{
				resultHeight = minHeight;
			}
			else if(resultHeight > maxHeight)
			{
				resultHeight = maxHeight;
			}
			result.y = resultHeight;
		}
		else
		{
			result.y = explicitHeight;
		}

		return result;
	}

	/**
	 * @inheritDoc
	 */
	public function resetVariableVirtualCache():Void
	{
		this._widthCache.splice(0, this._widthCache.length);
	}

	/**
	 * @inheritDoc
	 */
	public function resetVariableVirtualCacheAtIndex(index:Int, item:DisplayObject = null):Void
	{
		this._widthCache.remove(index);
		if(item != null)
		{
			this._widthCache[index] = item.width;
			this.dispatchEventWith(Event.CHANGE);
		}
	}

	/**
	 * @inheritDoc
	 */
	public function addToVariableVirtualCacheAtIndex(index:Int, item:DisplayObject = null):Void
	{
		var widthValue:Null<Float> = item != null ? item.width : null;
		this._widthCache.insert(index, widthValue);
	}

	/**
	 * @inheritDoc
	 */
	public function removeFromVariableVirtualCacheAtIndex(index:Int):Void
	{
		this._widthCache.splice(index, 1);
	}

	/**
	 * @inheritDoc
	 */
	public function getVisibleIndicesAtScrollPosition(scrollX:Float, scrollY:Float, width:Float, height:Float, itemCount:Int, result:Array<Int> = null):Array<Int>
	{
		if(result != null)
		{
			result.splice(0, result.length);
		}
		else
		{
			result = new Array();
		}
		if(!this._useVirtualLayout)
		{
			throw new IllegalOperationError("getVisibleIndicesAtScrollPosition() may be called only if useVirtualLayout is true.");
		}

		this.prepareTypicalItem(height - this._paddingTop - this._paddingBottom);
		var calculatedTypicalItemWidth:Float = this._typicalItem != null ? this._typicalItem.width : 0;
		var calculatedTypicalItemHeight:Float = this._typicalItem != null ? this._typicalItem.height : 0;

		var hasFirstGap:Bool = this._firstGap == this._firstGap; //!isNaN
		var hasLastGap:Bool = this._lastGap == this._lastGap; //!isNaN
		var resultLastIndex:Int = 0;
		var visibleTypicalItemCount:Int = Math.ceil(width / (calculatedTypicalItemWidth + this._gap));
		if(!this._hasVariableItemDimensions)
		{
			//this case can be optimized because we know that every item has
			//the same width
			var totalItemWidth:Float = itemCount * (calculatedTypicalItemWidth + this._gap) - this._gap;
			if(hasFirstGap && itemCount > 1)
			{
				totalItemWidth = totalItemWidth - this._gap + this._firstGap;
			}
			if(hasLastGap && itemCount > 2)
			{
				totalItemWidth = totalItemWidth - this._gap + this._lastGap;
			}
			var indexOffset:Int = 0;
			if(totalItemWidth < width)
			{
				if(this._horizontalAlign == HORIZONTAL_ALIGN_RIGHT)
				{
					indexOffset = Math.ceil((width - totalItemWidth) / (calculatedTypicalItemWidth + this._gap));
				}
				else if(this._horizontalAlign == HORIZONTAL_ALIGN_CENTER)
				{
					indexOffset = Math.ceil(((width - totalItemWidth) / (calculatedTypicalItemWidth + this._gap)) / 2);
				}
			}
			var minimum:Int = Std.int((scrollX - this._paddingLeft) / (calculatedTypicalItemWidth + this._gap));
			if(minimum < 0)
			{
				minimum = 0;
			}
			minimum -= indexOffset;
			//if we're scrolling beyond the final item, we should keep the
			//indices consistent so that items aren't destroyed and
			//recreated unnecessarily
			var maximum:Int = minimum + visibleTypicalItemCount;
			if(maximum >= itemCount)
			{
				maximum = itemCount - 1;
			}
			minimum = maximum - visibleTypicalItemCount;
			if(minimum < 0)
			{
				minimum = 0;
			}
			//for(var i:Int = minimum; i <= maximum; i++)
			var i:Int = minimum;
			while(i <= maximum)
			{
				result[resultLastIndex] = i;
				resultLastIndex++;
				i++;
			}
			return result;
		}
		var secondToLastIndex:Int = itemCount - 2;
		var maxPositionX:Float = scrollX + width;
		var positionX:Float = this._paddingLeft;
		var itemWidth:Float;
		//for(i = 0; i < itemCount; i++)
		for(i in 0 ... itemCount)
		{
			var gap:Float = this._gap;
			if(hasFirstGap && i == 0)
			{
				gap = this._firstGap;
			}
			else if(hasLastGap && i > 0 && i == secondToLastIndex)
			{
				gap = this._lastGap;
			}
			var cachedWidth:Float = this._widthCache[i];
			if(cachedWidth != cachedWidth) //isNaN
			{
				itemWidth = calculatedTypicalItemWidth;
			}
			else
			{
				itemWidth = cachedWidth;
			}
			var oldPositionX:Float = positionX;
			positionX += itemWidth + gap;
			if(positionX > scrollX && oldPositionX < maxPositionX)
			{
				result[resultLastIndex] = i;
				resultLastIndex++;
			}

			if(positionX >= maxPositionX)
			{
				break;
			}
		}

		//similar to above, in order to avoid costly destruction and
		//creation of item renderers, we're going to fill in some extra
		//indices
		var resultLength:Int = result.length;
		var visibleItemCountDifference:Int = visibleTypicalItemCount - resultLength;
		if(visibleItemCountDifference > 0 && resultLength > 0)
		{
			//add extra items before the first index
			var firstExistingIndex:Int = result[0];
			var lastIndexToAdd:Int = firstExistingIndex - visibleItemCountDifference;
			if(lastIndexToAdd < 0)
			{
				lastIndexToAdd = 0;
			}
			//for(i = firstExistingIndex - 1; i >= lastIndexToAdd; i--)
			var i:Int = firstExistingIndex - 1;
			while(i >= lastIndexToAdd)
			{
				result.unshift(i);
				i--;
			}
		}
		resultLength = result.length;
		resultLastIndex = resultLength;
		visibleItemCountDifference = visibleTypicalItemCount - resultLength;
		if(visibleItemCountDifference > 0)
		{
			//add extra items after the last index
			var startIndex:Int = resultLength > 0 ? (result[resultLength - 1] + 1) : 0;
			var endIndex:Int = startIndex + visibleItemCountDifference;
			if(endIndex > itemCount)
			{
				endIndex = itemCount;
			}
			//for(i = startIndex; i < endIndex; i++)
			for(i in startIndex ... endIndex)
			{
				result[resultLastIndex] = i;
				resultLastIndex++;
			}
		}
		return result;
	}

	/**
	 * @inheritDoc
	 */
	public function getScrollPositionForIndex(index:Int, items:Array<DisplayObject>, x:Float, y:Float, width:Float, height:Float, result:Point = null):Point
	{
		if(result == null)
		{
			result = new Point();
		}

		var calculatedTypicalItemWidth:Float = 0;
		var calculatedTypicalItemHeight:Float = 0;
		if(this._useVirtualLayout)
		{
			this.prepareTypicalItem(height - this._paddingTop - this._paddingBottom);
			calculatedTypicalItemWidth = this._typicalItem != null ? this._typicalItem.width : 0;
			calculatedTypicalItemHeight = this._typicalItem != null ? this._typicalItem.height : 0;
		}

		var hasFirstGap:Bool = this._firstGap == this._firstGap; //!isNaN
		var hasLastGap:Bool = this._lastGap == this._lastGap; //!isNaN
		var positionX:Float = x + this._paddingLeft;
		var lastWidth:Float = 0;
		var gap:Float = this._gap;
		var startIndexOffset:Int = 0;
		var endIndexOffset:Float = 0;
		var itemCount:Int = items.length;
		var totalItemCount:Int = itemCount;
		if(this._useVirtualLayout && !this._hasVariableItemDimensions)
		{
			totalItemCount += this._beforeVirtualizedItemCount + this._afterVirtualizedItemCount;
			if(index < this._beforeVirtualizedItemCount)
			{
				//this makes it skip the loop below
				startIndexOffset = index + 1;
				lastWidth = calculatedTypicalItemWidth;
				gap = this._gap;
			}
			else
			{
				startIndexOffset = this._beforeVirtualizedItemCount;
				endIndexOffset = index - items.length - this._beforeVirtualizedItemCount + 1;
				if(endIndexOffset < 0)
				{
					endIndexOffset = 0;
				}
				positionX += (endIndexOffset * (calculatedTypicalItemWidth + this._gap));
			}
			positionX += (startIndexOffset * (calculatedTypicalItemWidth + this._gap));
		}
		index -= Std.int(startIndexOffset + endIndexOffset);
		var secondToLastIndex:Int = totalItemCount - 2;
		var cachedWidth:Float = Math.NaN;
		//for(var i:Int = 0; i <= index; i++)
		var i:Int = 0;
		while(i <= index)
		{
			var item:DisplayObject = items[i];
			var iNormalized:Int = i + startIndexOffset;
			if(hasFirstGap && iNormalized == 0)
			{
				gap = this._firstGap;
			}
			else if(hasLastGap && iNormalized > 0 && iNormalized == secondToLastIndex)
			{
				gap = this._lastGap;
			}
			else
			{
				gap = this._gap;
			}
			if(this._useVirtualLayout && this._hasVariableItemDimensions)
			{
				cachedWidth = this._widthCache[iNormalized];
			}
			if(this._useVirtualLayout && item == null)
			{
				if(!this._hasVariableItemDimensions ||
					cachedWidth != cachedWidth) //isNaN
				{
					lastWidth = calculatedTypicalItemWidth;
				}
				else
				{
					lastWidth = cachedWidth;
				}
			}
			else
			{
				var itemWidth:Float = item.width;
				if(this._useVirtualLayout)
				{
					if(this._hasVariableItemDimensions)
					{
						if(itemWidth != cachedWidth)
						{
							this._widthCache[iNormalized] = itemWidth;
							this.dispatchEventWith(Event.CHANGE);
						}
					}
					else if(calculatedTypicalItemWidth >= 0)
					{
						item.width = itemWidth = calculatedTypicalItemWidth;
					}
				}
				lastWidth = itemWidth;
			}
			positionX += lastWidth + gap;
			
			i++;
		}
		positionX -= (lastWidth + gap);
		if(this._scrollPositionHorizontalAlign == HORIZONTAL_ALIGN_CENTER)
		{
			positionX -= Math.round((width - lastWidth) / 2);
		}
		else if(this._scrollPositionHorizontalAlign == HORIZONTAL_ALIGN_RIGHT)
		{
			positionX -= (width - lastWidth);
		}
		result.x = positionX;
		result.y = 0;

		return result;
	}

	/**
	 * @private
	 */
	private function validateItems(items:Array<DisplayObject>, justifyHeight:Float, distributedWidth:Float):Void
	{
		//if the alignment is justified, then we want to set the height of
		//each item before validating because setting one dimension may
		//cause the other dimension to change, and that will invalidate the
		//layout if it happens after validation, causing more invalidation
		var mustSetJustifyHeight:Bool = this._verticalAlign == VERTICAL_ALIGN_JUSTIFY &&
			justifyHeight == justifyHeight; //!isNaN

		var itemCount:Int = items.length;
		//for(var i:Int = 0; i < itemCount; i++)
		for(i in 0 ... itemCount)
		{
			var item:DisplayObject = items[i];
			if(item == null || (Std.is(item, ILayoutDisplayObject) && !cast(item, ILayoutDisplayObject).includeInLayout))
			{
				continue;
			}
			if(this._distributeWidths)
			{
				item.width = distributedWidth;
			}
			if(mustSetJustifyHeight)
			{
				item.height = justifyHeight;
			}
			if(Std.is(item, IValidating))
			{
				cast(item, IValidating).validate();
			}
		}
	}

	/**
	 * @private
	 */
	private function prepareTypicalItem(justifyHeight:Float):Void
	{
		if(this._typicalItem == null)
		{
			return;
		}
		if(this._resetTypicalItemDimensionsOnMeasure)
		{
			this._typicalItem.width = this._typicalItemWidth;
		}
		if(this._verticalAlign == VERTICAL_ALIGN_JUSTIFY &&
			justifyHeight == justifyHeight) //!isNaN
		{
			this._typicalItem.height = justifyHeight;
		}
		else if(this._resetTypicalItemDimensionsOnMeasure)
		{
			this._typicalItem.height = this._typicalItemHeight;
		}
		if(Std.is(this._typicalItem, IValidating))
		{
			cast(this._typicalItem, IValidating).validate();
		}
	}

	/**
	 * @private
	 */
	private function calculateDistributedWidth(items:Array<DisplayObject>, explicitWidth:Float, minWidth:Float, maxWidth:Float):Float
	{
		var itemCount:Int = items.length;
		if(explicitWidth != explicitWidth) //isNaN
		{
			var maxItemWidth:Float = 0;
			//for(var i:Int = 0; i < itemCount; i++)
			for(i in 0 ... itemCount)
			{
				var item:DisplayObject = items[i];
				var itemWidth:Float = item.width;
				if(itemWidth > maxItemWidth)
				{
					maxItemWidth = itemWidth;
				}
			}
			explicitWidth = maxItemWidth * itemCount + this._paddingLeft + this._paddingRight + this._gap * (itemCount - 1);
			var needsRecalculation:Bool = false;
			if(explicitWidth > maxWidth)
			{
				explicitWidth = maxWidth;
				needsRecalculation = true;
			}
			else if(explicitWidth < minWidth)
			{
				explicitWidth = minWidth;
				needsRecalculation = true;
			}
			if(!needsRecalculation)
			{
				return maxItemWidth;
			}
		}
		var availableSpace:Float = explicitWidth - this._paddingLeft - this._paddingRight - this._gap * (itemCount - 1);
		if(itemCount > 1 && this._firstGap == this._firstGap) //!isNaN
		{
			availableSpace += this._gap - this._firstGap;
		}
		if(itemCount > 2 && this._lastGap == this._lastGap) //!isNaN
		{
			availableSpace += this._gap - this._lastGap;
		}
		return availableSpace / itemCount;
	}

	/**
	 * @private
	 */
	private function applyPercentWidths(items:Array<DisplayObject>, explicitWidth:Float, minWidth:Float, maxWidth:Float):Void
	{
		var remainingWidth:Float = explicitWidth;
		this._discoveredItemsCache.splice(0, this._discoveredItemsCache.length);
		var totalExplicitWidth:Float = 0;
		var totalMinWidth:Float = 0;
		var totalPercentWidth:Float = 0;
		var itemCount:Int = items.length;
		var pushIndex:Int = 0;
		var layoutItem:ILayoutDisplayObject;
		var layoutData:HorizontalLayoutData;
		var percentWidth:Float;
		var feathersItem:IFeathersControl;
		var needsAnotherPass:Bool;
		//for(var i:Int = 0; i < itemCount; i++)
		for(i in 0 ... itemCount)
		{
			var item:DisplayObject = items[i];
			if(Std.is(item, ILayoutDisplayObject))
			{
				layoutItem = cast(item, ILayoutDisplayObject);
				if(!layoutItem.includeInLayout)
				{
					continue;
				}
				layoutData = safe_cast(layoutItem.layoutData, HorizontalLayoutData);
				if(layoutData != null)
				{
					percentWidth = layoutData.percentWidth;
					if(percentWidth == percentWidth) //!isNaN
					{
						if(Std.is(layoutItem, IFeathersControl))
						{
							feathersItem = cast(layoutItem, IFeathersControl);
							totalMinWidth += feathersItem.minWidth;
						}
						totalPercentWidth += percentWidth;
						this._discoveredItemsCache[pushIndex] = item;
						pushIndex++;
						continue;
					}
				}
			}
			totalExplicitWidth += item.width;
		}
		totalExplicitWidth += this._gap * (itemCount - 1);
		if(this._firstGap == this._firstGap && itemCount > 1)
		{
			totalExplicitWidth += (this._firstGap - this._gap);
		}
		else if(this._lastGap == this._lastGap && itemCount > 2)
		{
			totalExplicitWidth += (this._lastGap - this._gap);
		}
		totalExplicitWidth += this._paddingLeft + this._paddingRight;
		if(totalPercentWidth < 100)
		{
			totalPercentWidth = 100;
		}
		if(remainingWidth != remainingWidth) //isNaN
		{
			remainingWidth = totalExplicitWidth + totalMinWidth;
			if(remainingWidth < minWidth)
			{
				remainingWidth = minWidth;
			}
			else if(remainingWidth > maxWidth)
			{
				remainingWidth = maxWidth;
			}
		}
		remainingWidth -= totalExplicitWidth;
		if(remainingWidth < 0)
		{
			remainingWidth = 0;
		}
		do
		{
			needsAnotherPass = false;
			var percentToPixels:Float = remainingWidth / totalPercentWidth;
			//for(i = 0; i < pushIndex; i++)
			for(i in 0 ... pushIndex)
			{
				layoutItem = cast(this._discoveredItemsCache[i], ILayoutDisplayObject);
				if(layoutItem == null)
				{
					continue;
				}
				layoutData = cast(layoutItem.layoutData, HorizontalLayoutData);
				percentWidth = layoutData.percentWidth;
				var itemWidth:Float = percentToPixels * percentWidth;
				if(Std.is(layoutItem, IFeathersControl))
				{
					feathersItem = cast(layoutItem, IFeathersControl);
					var itemMinWidth:Float = feathersItem.minWidth;
					if(itemWidth < itemMinWidth)
					{
						itemWidth = itemMinWidth;
						remainingWidth -= itemWidth;
						totalPercentWidth -= percentWidth;
						this._discoveredItemsCache[i] = null;
						needsAnotherPass = true;
					}
					else
					{
						var itemMaxWidth:Float = feathersItem.maxWidth;
						if(itemWidth > itemMaxWidth)
						{
							itemWidth = itemMaxWidth;
							remainingWidth -= itemWidth;
							totalPercentWidth -= percentWidth;
							this._discoveredItemsCache[i] = null;
							needsAnotherPass = true;
						}
					}
				}
				layoutItem.width = itemWidth;
			}
		}
		while(needsAnotherPass);
		this._discoveredItemsCache.splice(0, this._discoveredItemsCache.length);
	}
}
