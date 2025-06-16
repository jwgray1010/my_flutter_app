export const generateInviteCode = (length = 5) => {
  const prefix = 'UNSD-';
  const random = Math.random().toString(36).substring(2, 2 + length).toUpperCase();
  return `${prefix}${random}`;
};
