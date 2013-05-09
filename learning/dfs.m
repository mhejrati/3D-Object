%

% orig_child : which part in the original order should we point to as child
% orig_pa : which part in the original order should we point to as parent
% new_pa : in the new order what is the parent

function [orig_child,orig_pa,new_pa] = dfs(pa)
  n_parts = length(pa);
  flag = true(1,n_parts);
  new_order = zeros(1,n_parts);
  orig_pa = zeros(1,n_parts);
  new_pa = zeros(1,n_parts);

  for i = 1:n_parts
    if pa(i)==0
      stack(1) = i;
      flag(i) = false;
      new_order(1) = i;
    end
  end

  cnt = 1;
  while length(stack)>0
    for i = 1:n_parts
      if pa(i)==stack(1) && flag(i)
        stack(end+1) = i;
        flag(i) = false;
        cnt = cnt+1;
        new_order(cnt) = i;
      end
    end
    stack = stack(2:end);
  end

  orig_child = new_order;
  for i = 2:n_parts
    new_pa(i) = find(new_order==pa(new_order(i)));
    orig_pa(i) = pa(new_order(i));
  end
% 
% 
% 
% for i = 1:n_parts
%   if pa(i)==0
%     stack(1) = i;
%     orig_child(1) = i;
%     tmp_pa(1) = 0;
%     tr(i) = 1;
%     flag(i) = false;
%   end
% end
% 
% cnt = 1;
% while length(stack)>0
%   for i = 1:n_parts
%     if pa(i)==stack(1) && flag(i)
%       stack(end+1) = i;
%       flag(i) = false;
%       cnt = cnt+1;
%       orig_child(cnt) = i;
%       tr(i) = cnt;
%       tmp_pa(cnt) = tr(pa(i));
%       n_pa(cnt) = pa(i);
%     end
%   end
%   stack = stack(2:end);
% end
% 
% pa = tmp_pa;