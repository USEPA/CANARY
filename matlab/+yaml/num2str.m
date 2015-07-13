function s = num2str(x, varargin)
  s = num2str(x, varargin{:});
  s = strrep(s, 'Inf', '.inf');
  s = strrep(s, 'NaN', '.nan');
end