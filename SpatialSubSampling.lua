local SpatialSubSampling, parent = torch.class('nn.SpatialSubSampling', 'nn.Module')

function SpatialSubSampling:__init(nInputPlane, kW, kH, dW, dH)
   parent.__init(self)

   dW = dW or 1
   dH = dH or 1

   self.nInputPlane = nInputPlane
   self.kW = kW
   self.kH = kH
   self.dW = dW
   self.dH = dH

   self.weight = torch.Tensor(nInputPlane)
   self.bias = torch.Tensor(nInputPlane)
   self.gradWeight = torch.Tensor(nInputPlane)
   self.gradBias = torch.Tensor(nInputPlane)
   
   self:reset()
end

function SpatialSubSampling:reset(stdv)
   if stdv then
      stdv = stdv * math.sqrt(3)
   else
      stdv = 1/math.sqrt(self.kW*self.kH)
   end
   if nn.oldSeed then
      self.weight:apply(function()
         return torch.uniform(-stdv, stdv)
      end)
      self.bias:apply(function()
         return torch.uniform(-stdv, stdv)
      end) 
   else
      self.weight:uniform(-stdv, stdv)
      self.bias:uniform(-stdv, stdv)
   end
end

function SpatialSubSampling:updateOutput(input)
   input.THNN.SpatialSubSampling_updateOutput(
      input,
      self.output,
      self.weight,
      self.bias,
      self.kW, self.kH,
      self.dW, self.dH
   )
   return self.output
end

function SpatialSubSampling:updateGradInput(input, gradOutput)
   if self.gradInput then
      input.THNN.SpatialSubSampling_updateGradInput(
         input,
         gradOutput,
         self.gradInput,
         self.weight,
         self.kW, self.kH,
         self.dW, self.dH
      )
      return self.gradInput
   end
end

function SpatialSubSampling:accGradParameters(input, gradOutput, scale)
   scale = scale or 1
   input.THNN.SpatialSubSampling_accGradParameters(
      input,
      gradOutput,
      self.gradWeight,
      self.gradBias,
      self.kW, self.kH,
      self.dW, self.dH,
      scale
   )
end
