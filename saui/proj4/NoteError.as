package saui.proj4
{
	/**
	 * NoteError class used when user tries action that isn't allowed.
	 * 
	 * No different than standard error class, just want to be able to catch these separately from other errors.
	 * 
	 * @author Jenny Schweers
	 */
	public class NoteError extends Error
	{
		public function NoteError(message:String="", id:int=0)
		{
			super(message, id);
		}
		
	}
}