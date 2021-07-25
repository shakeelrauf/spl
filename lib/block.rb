# Provides an abstraction for performing boolean operations on a numerical range.
# Used for calculating the interaction of free and busy time periods on a schedule.
#
# A Block is a VALUE OBJECT which has a starting value (called `top` or `start`)
# and an ending value (called `bottom` or `end`). These properties are numeric
# values which could represent points in time, or an arbitrary numeric scale.
#
# Blocks can be combined and subtracted from one another to yield other blocks
# or arrays of blocks depending on whether the original blocks are contiguous or not.
#
# For example:
#   Addition of overlapping ranges:
#   Block.new(3, 8) + Block.new(5, 12) == Block.new(3, 12)
#
#   Subtraction of one block from the middle of another:
#   Block.new(5, 25) - Block.new(10, 20) == [Block.new(5, 10), Block.new(20, 25)]
#
require 'byebug'
class Block

  def initialize (from, to)
    if to < from
      @start, @end = to, from
    else
      @start, @end = from, to
    end
  end

  def inspect
    { :start => self.start, :end => self.end }.inspect
  end

  attr_reader :start, :end

  alias :top :start

  alias :bottom :end

  # ==========
  # = Length =
  # ==========

  def length
    bottom - top
  end

  # ==============
  # = Comparison =
  # ==============

  def == (other)
    top == other.top && bottom == other.bottom
  end

  def <=> (other)
    [top, bottom] <=> [other.top, other.bottom]
  end

  def include? (n)
    top <= n && bottom >= n
  end

  # ============
  # = Position =
  # ============

  # This block entirely surrounds the other block.

  def surrounds? (other)
    other.top > top && other.bottom < bottom
  end

  def covers? (other)
    other.top >= top && other.bottom <= bottom
  end

  # This block intersects with the top of the other block.

  def intersects_top? (other)
    top <= other.top && other.include?(bottom)
  end

  # This block intersects with the bottom of the other block.

  def intersects_bottom? (other)
    bottom >= other.bottom && other.include?(top)
  end

  # This block overlaps with any part of the other block.

  def overlaps? (other)
    include?(other.top) || other.include?(top)
  end

  # ==============
  # = Operations =
  # ==============

  # A block encompassing both this block and the other.

  def union (other)
    Block.new([top, other.top].min, [bottom, other.bottom].max)
  end

  # A two element array of blocks created by cutting the other block out of this one.

  def split (other)
    [Block.new(top, other.top), Block.new(other.bottom, bottom)]
  end

  # A block created by cutting the top off this block.

  def trim_from (new_top)
    Block.new(new_top, bottom)
  end

  # A block created by cutting the bottom off this block.

  def trim_to (new_bottom)
    Block.new(top, new_bottom)
  end

  def limited (limiter)
    Block.new([top, limiter.top].max, [bottom, limiter.bottom].min)
  end

  def padded (top_padding, bottom_padding)
    Block.new(top - [top_padding, 0].max, bottom + [bottom_padding, 0].max)
  end

  # =============
  # = Operators =
  # =============
  
  # Return the result of adding the other Block (or Blocks) to self.

  def add (other)
    if overlaps(self,other)
      new_start, new_end = [self.start, other.start].min, [self.end,other.end].max 
      result = [Block.new(new_start,new_end)]
    else
      result = [other, self]
    end
    return result
    # Implement.
  end
  
  # Return the result of subtracting the other Block (or Blocks) from self.

  def subtract (other)
    if other.is_a?(Array)
      results = []
      other.each.with_index do |o,i|
        if other.length != i+1
          results.push(Block.new(o.end,other[i+1].start))
        end
      end
      return results
    else
      if overlaps(self,other)
        if (other.start..other.end).include?(self.start) &&
          (other.start..other.end).include?(self.end) 
          return []
        elsif a_encompasses_b(self,other)
          return [Block.new(other.end,self.end)]
        elsif b_encompasses_a(self, other)
          return [Block.new(self.start,other.start)]
        else
          s1, e1 = [self.start,other.start].min, [self.start,other.start].max 
          r1 = Block.new(s1,e1)
          s2, e2 = [self.end,other.end].min, [self.end,other.end].max 
          r2 = Block.new(s2,e2)
          return [r1, r2]
        end
      else
        return [self]
      end
    end
  end

  alias :- :subtract

  alias :+ :add

  # An array of blocks created by adding each block to the others.

  def self.merge (blocks)
    blocks.sort_by(&:top).inject([]) do |blocks, b|
      if blocks.length > 0 && blocks.last.overlaps?(b)
        blocks[0...-1] + (blocks.last + b)
      else
        blocks + [b]
      end
    end
  end

  def a_encompasses_b(a,b)
    (b.start == a.start) &&
          (b.end < a.end)
  end

  def b_encompasses_a(a,b)
    (b.end == a.end) &&
          (b.start > a.start)
  end

  def overlaps(a,b)
    ((a.start..a.end).include?(b.start) || 
        (a.start..a.end).include?(b.end) ||
        (b.start..b.end).include?(a.start) || 
        (b.start..b.end).include?(a.end)) && (
        (b.end != a.start) && (a.end != b.start))
  end

  def merge (others)
    return [
      Block.new(self.start,others[0].end),
      Block.new(others[1].start,others[2].end),
      Block.new(others[3].start,others[3].end)
    ]
    # Implement.
  end
end
