local SmoothL1Criterion, parent = torch.class('nn.SmoothL1Criterion', 'nn.Criterion')

function SmoothL1Criterion:__init(sizeAverage)
   parent.__init(self)
   if sizeAverage ~= nil then
     self.sizeAverage = sizeAverage
   else
     self.sizeAverage = true
   end
end

function SmoothL1Criterion:updateOutput(input, target)
   self.output_tensor = self.output_tensor or input.new(1)
   input.THNN.SmoothL1Criterion_updateOutput(
      input,
      target,
      self.output_tensor,
      self.sizeAverage
   )
   self.output = self.output_tensor[1]
   return self.output
end

function SmoothL1Criterion:updateGradInput(input, target)
   input.THNN.SmoothL1Criterion_updateGradInput(
      input,
      target,
      self.gradInput,
      self.sizeAverage
   )
   return self.gradInput
end
