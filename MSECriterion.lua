local MSECriterion, parent = torch.class('nn.MSECriterion', 'nn.Criterion')

function MSECriterion:__init(sizeAverage)
   parent.__init(self)
   if sizeAverage ~= nil then
     self.sizeAverage = sizeAverage
   else
     self.sizeAverage = true
   end
end

function MSECriterion:updateOutput(input, target)
   self.output_tensor = self.output_tensor or input.new(1)
   input.THNN.MSECriterion_updateOutput(
      input,
      target,
      self.output_tensor,
      self.sizeAverage
   )
   self.output = self.output_tensor[1]
   return self.output
end

function MSECriterion:updateGradInput(input, target)
   input.THNN.MSECriterion_updateGradInput(
      input,
      target,
      self.gradInput,
      self.sizeAverage
   )
   return self.gradInput
end
