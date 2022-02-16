local Rectangle = {}
Rectangle.__index = Rectangle

-- Constructor

function Rectangle.new(x, y, width, height)
  local rect = setmetatable({
    x = x,
    y = y,
    width = width,
    height = height,
  }, Rectangle)

  return rect
end

function Rectangle.from(other)
  return Rectangle.new(other.x, other.y, other.width, other.height)
end


-- Instance methods

function Rectangle:endX()
  return self.x + self.width
end

function Rectangle:endY()
  return self.y + self.height
end

function Rectangle:crop_to(other)
  local result = Rectangle.from(self)

  if other.x > result.x then
    local dx = other.x - result.x
    result.x = other.x
    result.width = math.max(0, result.width - dx)
  end
  if other:endX() < self:endX() then
    result.width =
      math.max(
        result.width - (self:endX() - other:endX()),
        0
      )
  end

  if other.y > result.y then
    local dy = other.y - result.y
    result.y = other.y
    result.height = math.max(0, result.height - dy)
  end
  if other:endY() < self:endY() then
    result.height =
      math.max(
        result.height - (self:endY() - other:endY()),
        0
      )
  end

  return result
end

function Rectangle:offset_to(other)
  return {
    x = other.x - self.x,
    y = other.y - self.y,
  }
end

function Rectangle:to_cells(cell_pixels)
  return Rectangle.new(
    self.x / cell_pixels.width,
    self.y / cell_pixels.height,
    self.width / cell_pixels.width,
    self.height / cell_pixels.height
  )
end

function Rectangle:to_pixels(cell_pixels)
  return Rectangle.new(
    self.x * cell_pixels.width,
    self.y * cell_pixels.height,
    self.width * cell_pixels.width,
    self.height * cell_pixels.height
  )
end

return Rectangle
