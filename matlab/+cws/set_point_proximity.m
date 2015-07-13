%SET_POINT_PROXIMITY Calculate event probability from proximity to limits
%
% CANARY: Water Quality Event Detection Algorithm Test & Evaluation Tool
% Copyright 2007-2009 Sandia Corporation.
% This source code is distributed under the LGPL License.
% Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
% the U.S. Government retains certain rights in this software.
%
% This library is free software; you can redistribute it and/or modify it
% under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation; either version 2.1 of the License, or (at
% your option) any later version. This library is distributed in the hope
% that it will be useful, but WITHOUT ANY WARRANTY; without even the
% implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with this library; if not, write to the Free Software Foundation,
% Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
%
% Author: Sean McKenna
%
% Read in the current data values for m signals, calcualte the probability
% of an event based on a normalized proximity to the set point limits and
% return a 1xm vector of P(event)
%
% Inputs
%    values     data (signal) values for the current time  (1xm vector)
%    precision  precision values for each sensor (1xm vector)
%    set_pt_lo   minimum set point values for each signal (1xm vector)
%    set_pt_hi   maximum set point values for each signal (1xm vector)
%    nprec      number of precision steps away from either set pt. limit where P(event) decays to zero
%    prob_dist  probability distribution to use (1 = exponential; 2 = beta)
%
% The nprec parameter is read in as the threshold parameter in the config file
% The prob_dist parameter is read in using a separate “mFile” parameter(STP1 = exponential; STP2 = beta).
%
% Outputs
%    pp         p(event) values for each signal (1xm vector)
%    err_code   0 if no error, 1 if nprec*precision is larger than half_range
function [pp, err_code] = set_point_proximity(values,precision,set_pt_lo,set_pt_hi,nprec,prob_dist)
  % Initialize
  range = set_pt_hi - set_pt_lo;           % range between set points
  qtr_range = range ./ 3.0;
  prec_dist = nprec .* precision;
  ispinf = isinf(set_pt_hi);
  isninf = isinf(set_pt_lo);
  range(isninf) = abs(set_pt_hi(isninf)*2.0);
  range(ispinf) = abs(set_pt_lo(ispinf)*2.0);
  half_range = range./2.0;               % half distance of range
  ctr_line = half_range + set_pt_lo;      % center value of range
  ctr_line(isninf) = 0;
  ctr_line(ispinf) = 0;
  qtr_range_prec = qtr_range ./ nprec;
  precision(qtr_range < prec_dist) = qtr_range_prec(qtr_range < prec_dist);
  
  % Check for overlapping regions of non-zero P(event)
  err_code = 0;
  idx = find(precision.*nprec>half_range);
  if (sum(idx)) > 0.0
    err_code = 1;
  end
  
  
  % Calculate distance from set point normalized by precision
  ndist = half_range - abs((values - ctr_line));  % raw distance from nearest set point
  ndist(ispinf) = (values(ispinf) - set_pt_lo(ispinf));
  ndist(isninf) = (set_pt_hi(isninf) - values(isninf));
  ndist = ndist ./ precision;                     % number of precision units in the raw distance
  ndist = ndist ./ nprec;                         % normalized distance from nearest set point
  
  
  % Call probability function with normalized distance
  switch lower(prob_dist)
    case {'stp1','sppe'}
      pp = expon_prob(ndist);
    case {'stp2','sppb'}
      pp = beta_prob(ndist);
  end
  pp(values<ctr_line) = -pp(values<ctr_line);
  pp(isinf(range)) = 0.0;
  
  
function pp = expon_prob(xx)
  
  % The parameter of the exponential distribution is hardcoded to provide a
  % single distribution, could read this parameter in at some pont if user
  % needs control over the shape of the distribution
  mu = 0.3;
  
  % USe complement of cdf to make P(event) higher as proximity to set point
  % decreases
  
  pp = 1.0 - expcdf(xx,mu);
  
  
function pp = beta_prob(dist)
  % Inputs
  %   dist - the normalized distance away from the centerline or to the
  %   nearest set point limit
  
  % THese are hardcoded to provide a bathtub distribution, could read these
  % in at some pont if user needs control over the shape of the distribution
  aa = 2.0;  % alpha parameter of beta distribution  (2.0)
  bb = 1.0;  % beta parameter of beta distribution   (1.0)
  
  % USe complement of cdf to make P(event) higher as proximity to set point
  % decreases
  pp = 1.0 - betacdf(dist,aa,bb);
