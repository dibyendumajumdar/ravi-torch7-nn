local MultiLabelMarginCriterion, parent = torch.class('nn.MultiLabelMarginCriterion', 'nn.Criterion')

function MultiLabelMarginCriterion:__init()
   parent.__init(self)
   self.sizeAverage = true
   self.isTarget = torch.Tensor()
end

function MultiLabelMarginCriterion:updateOutput(input, target)
   if torch.typename(input):find('torch%.Cuda.*Tensor') then
     target = torch.CudaLongTensor and target:cudaLong() or target
   else
     target = target:long()
   end
   self.output_tensor = self.output_tensor or input.new(1)
   input.THNN.MultiLabelMarginCriterion_updateOutput(
      input,
      target,
      self.output_tensor,
      self.isTarget,
      self.sizeAverage
   )
   self.output = self.output_tensor[1]
   return self.output
end

function MultiLabelMarginCriterion:updateGradInput(input, target)
   if torch.typename(input):find('torch%.Cuda.*Tensor') then
     target = torch.CudaLongTensor and target:cudaLong() or target
   else
     target = target:long()
   end
   input.THNN.MultiLabelMarginCriterion_updateGradInput(
      input,
      target,
      self.gradInput,
      self.isTarget,
      self.sizeAverage
   )
   return self.gradInput
end
